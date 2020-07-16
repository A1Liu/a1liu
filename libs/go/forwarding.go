package main

import (
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	// "time"
	// 	"os"
	// 	"os/signal"
)

func main() {
	var target string
	var port int
	flag.StringVar(&target, "target", "", "the target (<host>:<port>)")
	flag.IntVar(&port, "port", 8080, "the tunneling port")
	flag.Parse()

	incoming, err := net.Listen("tcp", fmt.Sprintf(":%d", port))
	if err != nil {
		log.Fatalf("could not start server on %d: %v", port, err)
	}
	fmt.Printf("server running on %d\n", port)

	client, err := incoming.Accept()
	if err != nil {
		log.Fatal("could not accept client connection", err)
	}
	defer client.Close()
	fmt.Printf("client '%v' connected!\n", client.RemoteAddr())

	targetPort, err := net.Dial("tcp", target)
	if err != nil {
		log.Fatal("could not connect to target", err)
	}
	defer targetPort.Close()
	fmt.Printf("connection to server %v established!\n", targetPort.RemoteAddr())

	go func() { io.Copy(targetPort, client) }()
	go func() { io.Copy(client, targetPort) }()

	// for {
	// 	time.Sleep(1)
	// }

}
