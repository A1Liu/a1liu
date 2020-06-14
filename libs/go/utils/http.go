package utils

import (
	"bytes"
	"image"
	_ "image/jpeg"
	_ "image/png"
	"io/ioutil"
	"mime/multipart"
	"net/http"
	"net/url"
	"strconv"
	"strings"
)

type QueryMap map[string]string

type responseData struct {
	Status        uint64
	StatusMessage string
	Body          []byte
}

type Response struct {
	Status        uint64
	StatusMessage string
	Body          string
}

type ImageResponse struct {
	Status        uint64
	StatusMessage string
	Body          image.Image
}

func SendFileUpload(urlString string, queryParams QueryMap, formParams url.Values, file []byte) Response {
	reqURL, err := url.Parse(urlString)
	IFailIf(err, "failed to parse url")

	q := reqURL.Query()
	for k, v := range queryParams {
		q.Add(k, v)
	}
	reqURL.RawQuery = q.Encode()

	body := new(bytes.Buffer)
	writer := multipart.NewWriter(body)
	part, err := writer.CreateFormFile("file", "file.jpeg")
	IFailIf(err, "couldn't create form file")
	part.Write(file)

	for k, values := range formParams {
		for _, v := range values {
			field, err := writer.CreateFormField(k)
			IFailIf(err, "failed creating form field")
			_, err = field.Write([]byte(v))
			IFailIf(err, "failed writing field")
		}
	}

	err = writer.Close()
	IFailIf(err, "couldn't close writer")

	req, err := http.NewRequest("POST", reqURL.String(), body)
	req.Header.Add("Content-Type", writer.FormDataContentType())
	IFailIf(err, "why did this fail?")

	resp, err := http.DefaultClient.Do(req)
	IFailIf(err, "Failed to perform POST file upload for url=%v", urlString)
	defer resp.Body.Close()

	statusMessage := strings.SplitN(resp.Status, " ", 2)
	statusCode, err := strconv.ParseUint(statusMessage[0], 10, 64)
	IFailIf(err, "failed to parse status code")

	responseBytes, err := ioutil.ReadAll(resp.Body)
	IFailIf(err, "bytes failed to read")

	return Response{statusCode, statusMessage[1], strings.TrimSpace(string(responseBytes))}
}

func SendImageRequest(method, urlString string, queryParams QueryMap,
	formValues url.Values) ImageResponse {
	data := sendRequest(method, urlString, queryParams, formValues)

	img, ext, err := image.Decode(bytes.NewReader(data.Body))
	IFailIf(err, "image failed to parse for ext="+ext)

	return ImageResponse{data.Status, data.StatusMessage, img}
}

func SendRequest(method, urlString string, queryParams QueryMap, formValues url.Values) (Response, error) {
	reqURL, err := url.Parse(urlString)
	if err != nil {
		return Response{}, err
	}

	q := reqURL.Query()
	for k, v := range queryParams {
		q.Add(k, v)
	}
	reqURL.RawQuery = q.Encode()

	var resp *http.Response
	if method == http.MethodPost {
		resp, err = http.PostForm(reqURL.String(), formValues)
	} else {
		var req http.Request
		req.URL = reqURL
		req.Method = method
		resp, err = http.DefaultClient.Do(&req)
	}

	if err != nil {
		return Response{}, err
	}
	defer resp.Body.Close()

	statusMessage := strings.SplitN(resp.Status, " ", 2)
	statusCode, err := strconv.ParseUint(statusMessage[0], 10, 64)
	if err != nil {
		return Response{}, err
	}

	responseBytes, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return Response{}, err
	}
	dataString := strings.TrimSpace(string(responseBytes))

	return Response{statusCode, statusMessage[1], dataString}, nil
}

func sendRequest(method, urlString string, queryParams QueryMap,
	formValues url.Values) responseData {
	reqURL, err := url.Parse(urlString)
	IFailIf(err, "failed to parse endpoint")

	q := reqURL.Query()
	for k, v := range queryParams {
		q.Add(k, v)
	}
	reqURL.RawQuery = q.Encode()

	var resp *http.Response
	if method == http.MethodPost {
		resp, err = http.PostForm(reqURL.String(), formValues)
	} else {
		var req http.Request
		req.URL = reqURL
		req.Method = method
		resp, err = http.DefaultClient.Do(&req)
	}

	IFailIf(err, "Failed to perform "+method+" for url="+urlString)
	defer resp.Body.Close()

	statusMessage := strings.SplitN(resp.Status, " ", 2)
	statusCode, err := strconv.ParseUint(statusMessage[0], 10, 64)
	IFailIf(err, "failed to parse status code")

	responseBytes, err := ioutil.ReadAll(resp.Body)
	IFailIf(err, "bytes failed to read")

	return responseData{statusCode, statusMessage[1], responseBytes}
}
