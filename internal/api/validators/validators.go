package validators

import (
	"time"

	"github.com/go-playground/validator/v10"
)

func RegisterCustomValidators(v *validator.Validate) error {
	return v.RegisterValidation("birthdate18", func(fl validator.FieldLevel) bool {
		birth, ok := fl.Field().Interface().(time.Time)
		if !ok {
			return false
		}
		now := time.Now()
		age := now.Year() - birth.Year()
		if now.YearDay() < birth.YearDay() {
			age--
		}
		return age >= 18
	})
}

