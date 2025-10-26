package server

import (
	"crypto/tls"
	"encoding/base64"
	"encoding/json"
	"errors"
	"os"
)

type CertificateStore struct {
	LE struct {
		Certificates []struct {
			Domain struct {
				Main string `json:"main"`
			} `json:"domain"`
			Certificate string `json:"certificate"`
			Key         string `json:"key"`
		} `json:"Certificates"`
	} `json:"le"`
}

func ParseCertificateStore(filePath string) (*tls.Certificate, error) {
	contents, err := os.ReadFile(filePath)
	if err != nil {
		return nil, err
	}

	var store CertificateStore
	if err = json.Unmarshal(contents, &store); err != nil {
		return nil, err
	}
	if len(store.LE.Certificates) == 0 {
		return nil, errors.New("no certificates found")
	}

	cert := store.LE.Certificates[0]
	certificateChain, err := base64.StdEncoding.DecodeString(cert.Certificate)
	if err != nil {
		return nil, err
	}
	privateKey, err := base64.StdEncoding.DecodeString(cert.Key)
	if err != nil {
		return nil, err
	}

	tlsCert, err := tls.X509KeyPair(certificateChain, privateKey)
	if err != nil {
		return nil, err
	}
	return &tlsCert, nil
}
