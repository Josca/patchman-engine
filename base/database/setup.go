package database

import (
	"app/base/utils"
	"fmt"
	"github.com/jinzhu/gorm"
	_ "github.com/jinzhu/gorm/dialects/postgres" // postgres used under gorm
	"strconv"
	"time"
)

var (
	Db *gorm.DB //nolint:stylecheck
)

// configure database, PostgreSQL or SQLite connection
func Configure() {
	pgConfig := loadEnvPostgreSQLConfig()
	Db = openPostgreSQL(pgConfig)
	check(Db)
}

// PostgreSQL database config
type PostgreSQLConfig struct {
	Host     string
	Port     int
	User     string
	Database string
	Passwd   string
	SSLMode  string

	// Additional params.
	StatementTimeoutMs     int // https://www.postgresql.org/docs/10/runtime-config-client.html
	MaxConnections         int
	MaxIdleConnections     int
	MaxConnectionLifetimeS int
}

// open database connection
func openPostgreSQL(dbConfig *PostgreSQLConfig) *gorm.DB {
	connectString := dataSourceName(dbConfig)
	db, err := gorm.Open("postgres", connectString)
	if err != nil {
		panic(err)
	}

	db.DB().SetMaxOpenConns(dbConfig.MaxConnections)
	db.DB().SetMaxIdleConns(dbConfig.MaxIdleConnections)
	db.DB().SetConnMaxLifetime(time.Duration(dbConfig.MaxConnectionLifetimeS) * time.Second)
	return db
}

// chcek if database connection works
func check(db *gorm.DB) {
	err := db.DB().Ping()
	if err != nil {
		panic(err)
	}
}

// load database config from environment vars using inserted prefix
func loadEnvPostgreSQLConfig() *PostgreSQLConfig {
	port, err := strconv.Atoi(utils.Getenv("DB_PORT", "FILL"))
	if err != nil {
		panic(err)
	}

	config := PostgreSQLConfig{
		User:     utils.Getenv("DB_USER", "FILL"),
		Host:     utils.Getenv("DB_HOST", "FILL"),
		Port:     port,
		Database: utils.Getenv("DB_NAME", "FILL"),
		Passwd:   utils.Getenv("DB_PASSWD", "FILL"),
		SSLMode:  utils.Getenv("DB_SSLMODE", "FILL"),

		StatementTimeoutMs:     utils.GetIntEnvOrDefault("DB_STATEMENT_TIMEOUT_MS", 0),
		MaxConnections:         utils.GetIntEnvOrDefault("DB_MAX_CONNECTIONS", 250),
		MaxIdleConnections:     utils.GetIntEnvOrDefault("DB_MAX_IDLE_CONNECTIONS", 50),
		MaxConnectionLifetimeS: utils.GetIntEnvOrDefault("DB_MAX_CONNECTION_LIFETIME_S", 60),
	}
	return &config
}

// create "data source" config string needed for database connection opening
func dataSourceName(dbConfig *PostgreSQLConfig) string {
	return fmt.Sprintf("host=%s port=%d user=%s dbname=%s password=%s sslmode=%s statement_timeout=%d",
		dbConfig.Host, dbConfig.Port, dbConfig.User, dbConfig.Database, dbConfig.Passwd, dbConfig.SSLMode,
		dbConfig.StatementTimeoutMs)
}
