package main

import (
	"bytes"
	"command_logs/lib"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net"
	"net/http"
	"os"
	"os/user"
	"path/filepath"
	"syscall"

	"github.com/sevlyar/go-daemon"
)

type LogData struct {
	Hostname  string `json:"hostname"`
	ExitCode  string `json:"exit_code"`
	Pwd       string `json:"pwd"`
	User      string `json:"user"`
	Timezone  string `json:"timezone"`
	Cmd       string `json:"cmd"`
	IsGit     bool   `json:"is_git"`
	GitRemote string `json:"git_remote"`
	GitBranch string `json:"git_branch"`
	GitCommit string `json:"git_commit"`
	CreatedAt string `json:"created_at"`
}

func ensureCacheDir() error {
	// Get the user's home directory
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get user home directory: %v", err)
	}

	// Build the path to the command_logs directory
	commandLogsDir := filepath.Join(homeDir, ".cache", "command_logs")

	// Check if the directory exists
	_, err = os.Stat(commandLogsDir)
	if os.IsNotExist(err) {
		// Create the directory
		err = os.MkdirAll(commandLogsDir, 0755)
		if err != nil {
			return fmt.Errorf("failed to create command_logs directory: %v", err)
		}
	} else if err != nil {
		// Return an error if there was an error checking the directory
		return fmt.Errorf("failed to check command_logs directory: %v", err)
	}

	return nil
}

func expandCachePath(path string) (string, error) {
	// Get the current user
	u, err := user.Current()
	if err != nil {
		return "", fmt.Errorf("failed to get current user: %v", err)
	}

	// Expand $HOME in the path
	path = os.ExpandEnv(path)
	path = filepath.Join(u.HomeDir, ".cache", "command_logs", path)

	return path, nil
}

func main() {
	if ensureCacheDir() != nil {
		os.Exit(1)
	}
	// Create a daemon context
	dir, _ := os.Getwd()
	socketPath := "/tmp/command_logs.sock"
	logfile, _ := expandCachePath("cmds.log")

	if len(os.Args) == 2 {
		socketPath = os.Args[1]
	}
	if len(os.Args) == 3 {
		logfile = os.Args[2]
	}
	fmt.Fprintf(os.Stderr, "logfile is %s, socket path is %s\n", logfile, socketPath)
	if lib.IsSocketAvailable(socketPath) {
		fmt.Fprintf(os.Stderr, "Another program is running and listen on %s\n", socketPath)
		os.Exit(int(syscall.EADDRINUSE))
	} else {
		_, err := os.Stat(socketPath)
		if err == nil {
			fmt.Fprintf(os.Stderr, "Socket file already exists, but seems not accessible\n")
			fmt.Fprintf(os.Stderr, "Removing %s ...", socketPath)
			os.Remove(socketPath)
			fmt.Fprintf(os.Stderr, "\t Removed\n")
		}
	}
	fmt.Fprintf(os.Stdout, "Starting ...\n")
	// Daemonsizing begin
	daemonContext := &daemon.Context{
		PidFileName: "/tmp/command_logs.pid",
		PidFilePerm: 0644,
		LogFileName: logfile,
		LogFilePerm: 0640,
		WorkDir:     dir,
		Umask:       027,
	}

	// Create a child process
	child, err := daemonContext.Reborn()
	if err != nil {
		fmt.Printf("Error reborn daemon: %v\n", err)
		return
	}

	if child != nil {
		return
	}

	defer daemonContext.Release()
	// Daemonsizing end

	defer os.Remove(socketPath)
	defer os.Remove("/tmp/command_logs.pid")
	// Get API key from env variable
	apiKey := os.Getenv("CMD_LOGS_API_KEY")
	if apiKey == "" {
		fmt.Fprintf(os.Stderr, "API_KEY environment variable is not set or empty\n")
		os.Exit(1)
	}

	// Get URL from env variable
	url := os.Getenv("CMD_LOGS_URL")
	if url == "" {
		fmt.Fprintf(os.Stderr, "URL environment variable is not set or empty\n")
		os.Exit(1)
	}

	// Check if URL is valid
	if _, err := http.NewRequest("HEAD", url, nil); err != nil {
		fmt.Fprintf(os.Stderr, "invalid URL: %v\n", err)
		os.Exit(1)
	}

	listener, err := net.Listen("unix", socketPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to listen on socket: %v\n", err)
		os.Exit(1)
	}

	fmt.Fprintf(os.Stdout, "Listen on %s... \n", socketPath)
	defer listener.Close()

	// Accept incoming connections and read data from TCP socket
	for {
		conn, err := listener.Accept()
		if err != nil {
			fmt.Fprintf(os.Stderr, "failed to accept incoming connection: %v\n", err)
			continue
		}

		// Read data from TCP socket
		var buf bytes.Buffer
		_, err = io.Copy(&buf, conn)
		if err != nil {
			fmt.Fprintf(os.Stderr, "failed to read data from TCP socket: %v\n", err)
			conn.Close()
			continue
		}
		if buf.String() == "bye" {
			conn.Close()
			break
		}

		if buf.String() == "ping" {
			_, err = conn.Write([]byte("pong"))
			if err != nil {
				fmt.Fprintf(os.Stderr, "failed to write pong: %v\n", err)
			}
			conn.Close()
			continue
		}
		// Close connection
		conn.Close()

		// Decode JSON data
		// Post data to AWS Lambda through Web API with API key authentication
		// Print HTTP response
		go newFunction(buf, socketPath, url, apiKey)
	}
}

func newFunction(buf bytes.Buffer, socketPath string, url string, apiKey string) {
	var logData LogData
	err := json.Unmarshal(buf.Bytes(), &logData)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to decode JSON data: %s %v\n", buf.String(), err)
	}

	if logData.Cmd == "stop command_logs" {
		fmt.Fprintf(os.Stderr, "Recevied stop command, exiting ... \n")
		os.Remove(socketPath)
		os.Exit(0)
	}

	fmt.Printf("Recevied JSON data: %s\n", buf.String())

	payload, err := json.Marshal(logData)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to marshal JSON payload: %v\n", err)
	}

	client := &http.Client{}
	req, err := http.NewRequest("POST", url, bytes.NewBuffer(payload))
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to create HTTP request: %v\n", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-api-key", apiKey)
	resp, err := client.Do(req)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to send HTTP request: %v\n", err)
	}

	body, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		fmt.Fprintf(os.Stderr, "failed to read HTTP response: %v\n", err)
	}
	fmt.Printf("HTTP response: %s\n", string(body))
	resp.Body.Close()
}
