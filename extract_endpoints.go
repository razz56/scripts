package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"sync"
)

func main() {
	srcDir := "scriptsresponse" // JS files base folder
	outDir := "endpoints"       // output folder

	// create output folder if not exists
	if err := os.MkdirAll(outDir, 0755); err != nil {
		fmt.Println("mkdir error:", err)
		return
	}

	// use all CPU cores for parallel processing
	workers := runtime.NumCPU()
	jobs := make(chan string, 100)
	var wg sync.WaitGroup

	// start worker goroutines
	for i := 0; i < workers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for path := range jobs {
				processFile(path, srcDir, outDir)
			}
		}()
	}

	// walk through all files in scriptsresponse
	filepath.Walk(srcDir, func(path string, info os.FileInfo, err error) error {
		if err == nil && !info.IsDir() {
			jobs <- path
		}
		return nil
	})

	close(jobs)
	wg.Wait()
}

func processFile(path, srcDir, outDir string) {
	// domain = parent folder name
	domain := filepath.Base(filepath.Dir(path))
	fileName := filepath.Base(path)

	// ensure domain output folder exists
	outPathDir := filepath.Join(outDir, domain)
	if err := os.MkdirAll(outPathDir, 0755); err != nil {
		fmt.Println("mkdir error:", err)
		return
	}

	outFile := filepath.Join(outPathDir, fileName)

	// ✅ Absolute path to your Ruby extractor
	rubyScript := "/home/rajrecon/Desktop/tools/relative-url-extractor/extract.rb"

	// run ruby extractor
	cmd := exec.Command("ruby", rubyScript, path)
	out, err := cmd.Output()
	if err != nil {
		fmt.Printf("error processing %s: %v\n", path, err)
		return
	}

	// write output
	if err := os.WriteFile(outFile, out, 0644); err != nil {
		fmt.Println("write error:", err)
	}
	fmt.Printf("Done: %s -> %s\n", path, outFile)
}
