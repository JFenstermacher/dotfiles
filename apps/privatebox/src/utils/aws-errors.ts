export function isCredentialsError(error: any): boolean {
  if (!error) return false;
  const name = error.name || "";
  return (
    name === "CredentialsProviderError" ||
    name === "TokenProviderError" ||
    name === "NoCredentials" ||
    name.includes("Credentials")
  );
}

export function isTimeoutError(error: any): boolean {
  if (!error) return false;
  const name = error.name || "";
  const message = error.message || "";
  return (
    name.includes("Timeout") ||
    name.includes("ETIMEDOUT") ||
    name.includes("ECONNRESET") ||
    message.includes("timeout") ||
    message.includes("ETIMEDOUT") ||
    message.includes("ECONNRESET")
  );
}