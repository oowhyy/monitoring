package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// Глобальный логгер
var logger *zap.Logger

// initLogger инициализирует глобальный логгер с настройкой для JSON
func initLogger() {
	// Настройка encoder для JSON формата (совместимо с Promtail)
	encoderConfig := zapcore.EncoderConfig{
		TimeKey:        "ts", // Promtail ожидает это поле
		LevelKey:       "level",
		NameKey:        "logger",
		CallerKey:      "caller",
		FunctionKey:    zapcore.OmitKey,
		MessageKey:     "msg", // Promtail ожидает это поле
		StacktraceKey:  "stacktrace",
		LineEnding:     zapcore.DefaultLineEnding,
		EncodeLevel:    zapcore.LowercaseLevelEncoder,
		EncodeTime:     zapcore.RFC3339NanoTimeEncoder, // ISO8601 формат
		EncodeDuration: zapcore.SecondsDurationEncoder,
		EncodeCaller:   zapcore.ShortCallerEncoder,
	}

	// Создаем core для записи в stdout (стандартный вывод)
	core := zapcore.NewCore(
		zapcore.NewJSONEncoder(encoderConfig),
		zapcore.AddSync(os.Stdout),
		zap.InfoLevel,
	)

	// Создание логгера
	logger = zap.New(core, zap.AddCaller(), zap.AddStacktrace(zapcore.ErrorLevel))

	logger.Info("Logger initialized - writing to stdout")
}

// getLogger возвращает глобальный логгер
func getLogger() *zap.Logger {
	return logger
}

// Service демонстрирует использование логгера в сервисе
type Service struct {
	name string
}

// NewService создает новый сервис с базовыми контекстными полями
func NewService(name string) *Service {
	return &Service{name: name}
}

// ProcessRequest демонстрирует структурированное логирование
func (s *Service) ProcessRequest(ctx context.Context, userID string, requestID string) error {
	// Создаем логгер с контекстными полями для всей функции
	log := getLogger().With(
		zap.String("service", s.name),
		zap.String("request_id", requestID),
		zap.String("user_id", userID),
	)

	log.Info("Starting request processing")

	// Добавляем дополнительные поля для конкретного лога
	log.Info("Processing step completed",
		zap.String("step", "validation"),
		zap.Duration("duration", 50*time.Millisecond),
		zap.Bool("success", true),
	)

	// Демонстрация разных уровней логирования
	log.Debug("Debug information", zap.Any("debug_data", map[string]interface{}{
		"memory_usage": "45MB",
		"goroutines":   12,
	}))

	log.Warn("Warning message", zap.String("reason", "high_load"))

	// Симуляция ошибки (закомментировано для демо)
	// return fmt.Errorf("processing failed")

	log.Info("Request processing completed",
		zap.Duration("total_duration", 100*time.Millisecond),
		zap.String("status", "success"),
	)

	return nil
}

// DatabaseService демонстрирует наследование контекстных тегов
type DatabaseService struct {
	baseLogger *zap.Logger
}

// NewDatabaseService создает сервис БД с базовыми контекстными полями
func NewDatabaseService() *DatabaseService {
	// Создаем базовый логгер с контекстом для всех операций БД
	baseLogger := getLogger().With(
		zap.String("component", "database"),
		zap.String("db_host", "localhost:5432"),
	)

	return &DatabaseService{
		baseLogger: baseLogger,
	}
}

// Query демонстрирует как контекстные теги наследуются и расширяются
func (db *DatabaseService) Query(query string, args ...interface{}) {
	// Наследуем базовые теги и добавляем новые
	log := db.baseLogger.With(
		zap.String("operation", "query"),
		zap.String("query", query),
		zap.Int("args_count", len(args)),
	)

	log.Info("Executing database query")

	// Симуляция выполнения
	time.Sleep(50 * time.Millisecond)

	log.Info("Query executed successfully",
		zap.Duration("execution_time", 50*time.Millisecond),
		zap.Int("rows_affected", 1),
	)
}

// Transaction демонстрирует вложенное контекстное логирование
func (db *DatabaseService) Transaction(txID string, operations []string) {
	// Создаем логгер для транзакции с наследованием базовых полей
	txLogger := db.baseLogger.With(
		zap.String("transaction_id", txID),
		zap.String("operation", "transaction"),
	)

	txLogger.Info("Starting database transaction",
		zap.Int("operations_count", len(operations)))

	for i, op := range operations {
		// Для каждой операции создаем еще более специфичный логгер
		opLogger := txLogger.With(
			zap.Int("operation_index", i),
			zap.String("operation_type", op),
		)

		opLogger.Debug("Executing operation")
		time.Sleep(20 * time.Millisecond)
		opLogger.Info("Operation completed")
	}

	txLogger.Info("Transaction completed successfully",
		zap.Duration("total_duration", time.Duration(len(operations))*20*time.Millisecond))
}

func main() {
	// Инициализация глобального логгера
	initLogger()
	defer logger.Sync() // Flush буферов при завершении

	logger.Info("=== Zap Logger Demo Started ===")

	// Демонстрация базового использования глобального логгера
	logger.Info("Basic logging example",
		zap.String("version", "1.0.0"),
		zap.Time("start_time", time.Now()),
	)

	// Демонстрация сервиса с контекстными полями
	service := NewService("user-service")
	ctx := context.Background()

	err := service.ProcessRequest(ctx, "user123", "req456")
	if err != nil {
		logger.Error("Request processing failed", zap.Error(err))
	}

	// Демонстрация наследования контекстных тегов
	dbService := NewDatabaseService()

	dbService.Query("SELECT * FROM users WHERE id = $1", 123)

	dbService.Transaction("tx789", []string{"insert", "update", "delete"})

	// Демонстрация разных уровней логирования
	logger.Debug("Debug level message")
	logger.Info("Info level message")
	logger.Warn("Warning level message")
	logger.Error("Error level message", zap.Error(fmt.Errorf("example error")))

	// Демонстрация структурированных данных
	logger.Info("Complex structured data",
		zap.Object("user", zapcore.ObjectMarshalerFunc(func(enc zapcore.ObjectEncoder) error {
			enc.AddString("id", "user123")
			enc.AddString("email", "user@example.com")
			enc.AddBool("active", true)
			enc.AddArray("roles", zapcore.ArrayMarshalerFunc(func(enc zapcore.ArrayEncoder) error {
				enc.AppendString("admin")
				enc.AppendString("user")
				return nil
			}))
			return nil
		})),
	)

	logger.Info("=== Zap Logger Demo Completed ===")
}
