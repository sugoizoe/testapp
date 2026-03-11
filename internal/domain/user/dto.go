package user

import "time"

type RegisterRequest struct {
	Email                  string    `json:"email" binding:"required,email" validate:"required,email"`
	Password               string    `json:"password" binding:"required,min=8,max=72" validate:"required,min=8,max=72"`
	BirthDate              time.Time `json:"birth_date" binding:"required" time_format:"2006-01-02" validate:"required,birthdate18"`
	Gender                 string    `json:"gender" binding:"required,oneof=male female other" validate:"required,oneof=male female other"`
	TargetGenderPreference string    `json:"target_gender_preference" binding:"required,oneof=male female both any" validate:"required,oneof=male female both any"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email" validate:"required,email"`
	Password string `json:"password" binding:"required" validate:"required"`
}

