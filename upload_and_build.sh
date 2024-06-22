flutter build apk --release

if [ $? -ne 0]; then
    echo '플러터 빌드 실패!'
    exit 1
fi

APK_PATH="build\app\outputs\flutter-apk\app-release.apk"

SERVER_URL="http://localhost:3000/api/file-server/upload"

version="0.1.1"
project="stock-master"

echo 'APK 파일 업로드...'
http_code=$(curl -o response.txt -w "%{http_code}" -F "version=$version" -F "project=$project" -F "file=@$APK_PATH" $SERVER_URL)

if [ "$http_code" -eq 200 ]; then
    echo '파일 업로드 성공!'
else
    echo "파일 업로드 실패, 실패 코드: $http_code"
    cat response.txt
    exit 1
fi

rm response.txt

echo "빌드 및 업로드 종료"