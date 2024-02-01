package prompts

import (
	"github.com/cqroot/prompt"
)

func Continue() (bool, error) {
	val, err := prompt.New().Ask("Continue?").Choose([]string{"Yes", "No"})
	if err != nil {
		return false, err
	}

	if val == "Yes" {
		return true, nil
	}

	return false, nil
}
