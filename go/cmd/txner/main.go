package main

import (
	"encoding/csv"
	"fmt"
	"os"

	"go.uber.org/zap"
)

func main() {
	logger, err := zap.NewProduction()
	if err != nil {
		panic("failed to initizalize logger")
	}
	logger.Info("logger is ready")

	file, err := os.Open("txns.csv")
	if err != nil {
		logger.Fatal(err.Error())
	}
	defer file.Close()

	reader := csv.NewReader(file)

	records, err := reader.ReadAll()
	if err != nil {
		logger.Fatal(err.Error())
	}

	for _, row := range records {
		for _, col := range row {
			fmt.Printf("%s\t", col)
		}
		fmt.Println()
	}

	// file reader returns records

	// txner applies business and save
	// emit events

	// mailer sends mail
}
