package release

import (
	_ "embed"
	"runtime"
	"strings"
)

//go:embed version.txt
var version string
var BuildArch string = ""

func GetSystemInfo() (string, string, string) {
	arch := BuildArch
	variant := ""

	if arch == "" {
		arch = runtime.GOARCH
	}

	if strings.Contains(arch, "arm") {
		splitArmArch := strings.Split(arch, "v")
		if len(splitArmArch) == 2 {
			variant = "v" + splitArmArch[1]
			arch = "arm"
		}
	}

	return runtime.GOOS, arch, variant
}

func GetVersion() string {
	return strings.TrimSpace(version)
}

func GetBuildArch() string {
	if BuildArch == "" {
		_, arch, variant := GetSystemInfo()
		BuildArch = arch + variant
	}
	return BuildArch
}
