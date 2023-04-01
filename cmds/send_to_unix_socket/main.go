package main

import (
	"bufio"
	"fmt"
	"net"
	"os"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: ./program <socket-path>")
		return
	}
	socketPath := os.Args[1]

	// Connect to Unix socket
	conn, err := net.DialUnix("unix", nil, &net.UnixAddr{Name: socketPath, Net: "unix"})
	if err != nil {
		fmt.Printf("Failed to connect to Unix socket: %v\n", err)
		return
	}
	defer conn.Close()

	// Read from stdin and send to socket
	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		message := scanner.Text()
		fmt.Printf("Received: %s\n", message)
		_, err := conn.Write([]byte(message))
		if err != nil {
			fmt.Printf("Failed to send message: %v\n", err)
			return
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Printf("Failed to read from stdin: %v\n", err)
		return
	}
}
