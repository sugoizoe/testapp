package service

import (
	"context"
	"fmt"

	"github.com/example/datenow/internal/repository/postgres"
	"github.com/example/datenow/pkg/rtc"
)

type CallService struct {
	callRepo   *postgres.CallRepository
	rtcService *rtc.Service
}

func NewCallService(callRepo *postgres.CallRepository, rtcService *rtc.Service) *CallService {
	return &CallService{
		callRepo:   callRepo,
		rtcService: rtcService,
	}
}

type InitiateCallResult struct {
	CalleeID string
	MatchID  string
}

func (s *CallService) InitiateCall(ctx context.Context, callerID, matchID string) (*InitiateCallResult, error) {
	info, err := s.callRepo.ValidateMatchAndRoles(ctx, matchID, callerID)
	if err != nil {
		return nil, fmt.Errorf("invalid match or permissions: %w", err)
	}
	return &InitiateCallResult{
		CalleeID: info.CalleeID,
		MatchID:  info.MatchID,
	}, nil
}

type AcceptCallResult struct {
	ChannelName string
	CallerToken string
	CalleeToken string
	CallerID    string
	CalleeID    string
}

func (s *CallService) AcceptCall(ctx context.Context, accepterID, matchID string) (*AcceptCallResult, error) {
	info, err := s.callRepo.ValidateMatchAndRoles(ctx, matchID, accepterID)
	if err != nil {
		return nil, fmt.Errorf("invalid match or permissions: %w", err)
	}

	// Channel adını deterministic üretelim ki her iki taraf da aynı odada buluşsun.
	channelName := fmt.Sprintf("match_%s", info.MatchID)

	callerRole := rtc.RoleCaller
	calleeRole := rtc.RoleCallee

	callerToken, _, err := s.rtcService.GenerateToken(channelName, info.CallerID, callerRole, info.CallerPremium)
	if err != nil {
		return nil, fmt.Errorf("generate caller token: %w", err)
	}
	calleeToken, _, err := s.rtcService.GenerateToken(channelName, info.CalleeID, calleeRole, info.CalleePremium)
	if err != nil {
		return nil, fmt.Errorf("generate callee token: %w", err)
	}

	return &AcceptCallResult{
		ChannelName: channelName,
		CallerToken: callerToken,
		CalleeToken: calleeToken,
		CallerID:    info.CallerID,
		CalleeID:    info.CalleeID,
	}, nil
}

