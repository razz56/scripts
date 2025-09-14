package main

import (
	"bufio"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run fetch.go targets.txt")
		return
	}
	inputFile := os.Args[1]

	// folders create
	os.MkdirAll("headers", 0755)
	os.MkdirAll("responsebody", 0755)

	file, err := os.Open(inputFile)
	if err != nil {
		fmt.Println("Error opening file:", err)
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	client := &http.Client{}

	for scanner.Scan() {
		url := strings.TrimSpace(scanner.Text())
		if url == "" {
			continue
		}

		// domain निकालना (https://abc.com/path → abc.com)
		domain := extractDomain(url)
		if domain == "" {
			fmt.Println("Skipping invalid URL:", url)
			continue
		}
		fmt.Println("Processing:", domain)

		// === Headers ===
		reqHead, _ := http.NewRequest("GET", url, nil)
		reqHead.Header.Set("X-Forwarded-For", "evil.com")
		respHead, err := client.Do(reqHead)
		if err == nil {
			saveHeaders(respHead, filepath.Join("headers", domain))
			respHead.Body.Close()
		} else {
			fmt.Println("Header error:", err)
		}

		// === Body ===
		reqBody, _ := http.NewRequest("GET", url, nil)
		reqBody.Header.Set("X-Forwarded-For", "evil.com")
		respBody, err := client.Do(reqBody)
		if err == nil {
			saveBody(respBody, filepath.Join("responsebody", domain))
			respBody.Body.Close()
		} else {
			fmt.Println("Body error:", err)
		}
	}

	if err := scanner.Err(); err != nil {
		fmt.Println("Scanner error:", err)
	}
}

func extractDomain(u string) string {
	// Remove scheme
	if strings.HasPrefix(u, "http://") {
		u = strings.TrimPrefix(u, "http://")
	} else if strings.HasPrefix(u, "https://") {
		u = strings.TrimPrefix(u, "https://")
	}
	parts := strings.SplitN(u, "/", 2)
	return parts[0]
}

func saveHeaders(resp *http.Response, path string) {
	f, err := os.Create(path)
	if err != nil {
		fmt.Println("File create error:", err)
		return
	}
	defer f.Close()

	fmt.Fprintf(f, "HTTP/%d.%d %s\n", resp.ProtoMajor, resp.ProtoMinor, resp.Status)
	for k, v := range resp.Header {
		fmt.Fprintf(f, "%s: %s\n", k, strings.Join(v, ", "))
	}
}

func saveBody(resp *http.Response, path string) {
	f, err := os.Create(path)
	if err != nil {
		fmt.Println("File create error:", err)
		return
	}
	defer f.Close()

	io.Copy(f, resp.Body)
}
