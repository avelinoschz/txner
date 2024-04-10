package main

import (
	"go.uber.org/zap"
)

func main() {
	logger, err := zap.NewProduction()
	if err != nil {
		panic("failed to initizalize logger")
	}
	logger.Info("logger is ready")
}
