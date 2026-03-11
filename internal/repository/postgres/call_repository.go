package postgres

import (
	"context"
	"fmt"

	"github.com/jackc/pgx/v5/pgxpool"
)

type CallRepository struct {
	db *pgxpool.Pool
}

func NewCallRepository(db *pgxpool.Pool) *CallRepository {
	return &CallRepository{db: db}
}

type MatchInfo struct {
	MatchID      string
	CallerID     string
	CalleeID     string
	CallerPremium bool
	CalleePremium bool
}

// ValidateMatchAndRoles: match_id ve caller'ın bu match'e ait olduğunu doğrular,
// karşı tarafın userID'sini ve premium durumlarını döner.
func (r *CallRepository) ValidateMatchAndRoles(ctx context.Context, matchID, callerID string) (*MatchInfo, error) {
	var info MatchInfo

	err := r.db.QueryRow(ctx, `
		SELECT
			m.id,
			m.user1_id,
			m.user2_id,
			u1.is_premium,
			u2.is_premium
		FROM matches m
		JOIN users u1 ON u1.id = m.user1_id
		JOIN users u2 ON u2.id = m.user2_id
		WHERE m.id = $1
		  AND (m.user1_id = $2 OR m.user2_id = $2)
	`, matchID, callerID).Scan(
		&info.MatchID,
		&info.CallerID,
		&info.CalleeID,
		&info.CallerPremium,
		&info.CalleePremium,
	)
	if err != nil {
		return nil, fmt.Errorf("validate match: %w", err)
	}

	// callerID'nin gerçekten hangi tarafta olduğunu düzelt
	if info.CallerID != callerID && info.CalleeID == callerID {
		info.CallerID, info.CalleeID = info.CalleeID, info.CallerID
		info.CallerPremium, info.CalleePremium = info.CalleePremium, info.CallerPremium
	}

	return &info, nil
}

