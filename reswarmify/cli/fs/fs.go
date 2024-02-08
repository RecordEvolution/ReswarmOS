package fs

import (
	"archive/tar"
	"compress/gzip"
	"fmt"
	"io"
	"os"
	"path/filepath"
)

func ReswarmifyRootfs() error {
	err := DownloadFile(ROOTFS_REMOTE_URL, ROOTFS_TEMP_TAR_GZ)
	if err != nil {
		return err
	}

	if err := os.MkdirAll(ROOTFS_TEMP_DIR, 0755); err != nil {
		return err
	}

	err = ExtractTarGz(ROOTFS_TEMP_TAR_GZ, ROOTFS_TEMP_DIR)
	if err != nil {
		return err
	}

	return OverlayDir(fmt.Sprintf("%s/rootfs", ROOTFS_TEMP_DIR), "/")
}

func OverlayDir(src string, dest string) error {
	return filepath.Walk(src, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		destPath := filepath.Join(dest, path[len(src):])

		if info.IsDir() {
			return os.MkdirAll(destPath, os.ModePerm)
		}

		srcFile, err := os.Open(path)
		if err != nil {
			return err
		}

		defer srcFile.Close()

		destFile, err := os.Create(destPath)
		if err != nil {
			return err
		}

		defer destFile.Close()

		_, err = io.Copy(destFile, srcFile)
		if err != nil {
			return err
		}

		return destFile.Chmod(0755)
	})
}

func ExtractTarGz(source, dest string) error {
	gzipFile, err := os.Open(source)
	if err != nil {
		return err
	}

	defer gzipFile.Close()

	gzipReader, err := gzip.NewReader(gzipFile)
	if err != nil {
		return err
	}

	defer gzipReader.Close()

	tarReader := tar.NewReader(gzipReader)

	for {
		header, err := tarReader.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			return err
		}

		target := filepath.Join(dest, header.Name)

		switch header.Typeflag {
		case tar.TypeDir:
			if err := os.MkdirAll(target, 0755); err != nil {
				return err
			}
		case tar.TypeReg:
			file, err := os.Create(target)
			if err != nil {
				return err
			}
			defer file.Close()

			if _, err := io.Copy(file, tarReader); err != nil {
				return err
			}

			err = file.Chmod(0755)
			if err != nil {
				return err
			}
		default:
			return fmt.Errorf("unknown type: %v in %s", header.Typeflag, header.Name)
		}
	}

	return nil
}
