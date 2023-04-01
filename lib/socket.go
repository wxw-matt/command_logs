package lib

import (
	"fmt"
	"net"
	"os"
)

func IsSocketAvailable(socketPath string) bool {
	// Check if Unix socket exists
	if _, err := os.Stat(socketPath); os.IsNotExist(err) {
		return false
	} else if err != nil {
		return false
	}

	// Check if Unix socket is still in use
	conn, err := net.DialUnix("unix", nil, &net.UnixAddr{Name: socketPath, Net: "unix"})
	if err != nil {
		return false
	}
	defer conn.Close()

	_, err = conn.Write([]byte("ping"))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to send 'ping' message: %v", err)
		return false
	}
	conn.CloseWrite()

	// Read "pong" response
	buf := make([]byte, 4)
	_, err = conn.Read(buf)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Failed to receive 'pong' message: %v", err)
		return false
	}
	if string(buf) != "pong" {
		fmt.Fprintf(os.Stderr, "Unexpected response received: %s", string(buf))
		return false
	}
	return true
}
