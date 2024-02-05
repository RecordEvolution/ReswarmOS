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
	err := DownloadFileWithProgress(ROOTFS_REMOTE_URL, ROOTFS_TEMP_TAR_GZ)
	if err != nil {
		return err
	}

	return OverlayDir(ROOTFS_TEMP_DIR, "/")
}

func OverlayDir(src string, dest string) error {
	if err := os.MkdirAll(dest, os.ModePerm); err != nil {
		return err
	}

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

		return nil
	})
}

func ExtractTarGzWithProgress(tarGzFile string, destFolder string) error {
	file, err := os.Open(tarGzFile)
	if err != nil {
		return err
	}
	defer file.Close()

	fileInfo, err := file.Stat()
	if err != nil {
		return err
	}
	totalSize := fileInfo.Size()

	gzipReader, err := gzip.NewReader(file)
	if err != nil {
		return err
	}
	defer gzipReader.Close()

	tarReader := tar.NewReader(gzipReader)

	buf := make([]byte, 0)
	var bytesRead int64

	for {
		header, err := tarReader.Next()

		if err == io.EOF {
			break
		}

		if err != nil {
			return err
		}

		filePath := filepath.Join(destFolder, header.Name)

		switch header.Typeflag {
		case tar.TypeDir:
			if err := os.MkdirAll(filePath, 0755); err != nil {
				return err
			}
		case tar.TypeReg:
			file, err := os.Create(filePath)
			if err != nil {
				return err
			}
			defer file.Close()

			n, err := io.CopyBuffer(file, tarReader, buf)
			if err != nil {
				return err
			}
			bytesRead += n

			progress := bytesRead / totalSize * 100
			fmt.Printf("\rProgress: %d", progress)

		default:
			return fmt.Errorf("unsupported file type in tar archive: %d", header.Typeflag)
		}
	}

	// Move to the next line after completion
	fmt.Print("\n")

	return nil
}
