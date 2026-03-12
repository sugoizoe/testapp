package main

import (
	"context"
	"fmt"
	"io/ioutil"
	"log"
	"path/filepath"
	"sort"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	dbURL := "postgres://datenow_user:supersecurepassword@localhost:5432/datenow?sslmode=disable"
	pool, err := pgxpool.New(context.Background(), dbURL)
	if err != nil {
		log.Fatalf("failed to connect: %v", err)
	}
	defer pool.Close()

	// Drop all existing tables first
	fmt.Println("Dropping existing tables...")
	_, err = pool.Exec(context.Background(), `
		DROP TABLE IF EXISTS fcm_tokens CASCADE;
		DROP TABLE IF EXISTS user_reports CASCADE;
		DROP TABLE IF EXISTS user_blocks CASCADE;
		DROP TABLE IF EXISTS status_requests CASCADE;
		DROP TABLE IF EXISTS statuses CASCADE;
		DROP TABLE IF EXISTS messages CASCADE;
		DROP TABLE IF EXISTS subscriptions CASCADE;
		DROP TABLE IF EXISTS refresh_tokens CASCADE;
		DROP TABLE IF EXISTS matches CASCADE;
		DROP TABLE IF EXISTS swipes CASCADE;
		DROP TABLE IF EXISTS profiles CASCADE;
		DROP TABLE IF EXISTS users CASCADE;
		DROP FUNCTION IF EXISTS haversine_distance_km CASCADE;
	`)
	if err != nil {
		log.Printf("warning: drop tables error (may be ok): %v", err)
	}
	fmt.Println("Tables dropped successfully.")

	migrationsDir := "migrations"
	files, err := ioutil.ReadDir(migrationsDir)
	if err != nil {
		log.Fatalf("read dir err: %v", err)
	}

	var sqlFiles []string
	for _, f := range files {
		if !f.IsDir() && filepath.Ext(f.Name()) == ".sql" {
			sqlFiles = append(sqlFiles, f.Name())
		}
	}
	sort.Strings(sqlFiles)

	for _, fname := range sqlFiles {
		content, err := ioutil.ReadFile(filepath.Join(migrationsDir, fname))
		if err != nil {
			log.Fatalf("read file %s err: %v", fname, err)
		}

		fmt.Printf("Applying %s...\n", fname)
		_, err = pool.Exec(context.Background(), string(content))
		if err != nil {
			log.Fatalf("exec %s err: %v", fname, err)
		}
		fmt.Printf("Applied %s successfully.\n", fname)
	}
	fmt.Println("All migrations applied successfully!")
}
