//usr/bin/env go run $0 $@; exit //allows you to run ./fs.go

// Simple Go webserver Hello World example 

package main

import (
    "os"
    "fmt"
    "log"
    "net/http"
)

func helloHandler(w http.ResponseWriter, r *http.Request)  {

    name, err := os.Hostname()

    if err != nil {
                 panic(err)
         }

    fmt.Println("Hostname reported by kernel : ", name)
        
    fmt.Fprintln(w, "Hello World")
    fmt.Fprintln(w, "Container Hostname : ", name)
}

func main() {
 
    fmt.Println("Starting Simple Go Webserver @ http://localhost:80")

    // Write Hello World message
    http.HandleFunc("/", helloHandler)

    err := http.ListenAndServe(":80", nil)
    if err != nil {
                log.Fatal(err)
        }
}
