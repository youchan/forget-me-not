export function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.content
}

export async function postJSON(url, body) {
  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Accept": "application/json",
      "X-CSRF-Token": csrfToken()
    },
    body: JSON.stringify(body)
  })

  const data = await response.json()

  if (!response.ok) {
    throw new Error(data.error || "リクエストに失敗したで")
  }

  return data
}
