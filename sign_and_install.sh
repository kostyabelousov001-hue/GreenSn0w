set -e

zsign -k ./.sign/pkey.p12 -p 1234 -m ./.sign/development.cer -b $1 -m ./.sign/profile.mobileprovision -o ./.sign/GreenSn0w.signed.ipa ./Application/GreenSn0w.ipa
ideviceinstaller install ./.sign/GreenSn0w.signed.ipa