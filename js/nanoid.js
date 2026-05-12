// Inline nanoid implementation — 8-char URL-safe IDs
// Alphabet: lowercase + digits (36 chars)
const ALPHABET = 'abcdefghijklmnopqrstuvwxyz0123456789';
const ID_LENGTH = 8;

function nanoid() {
  const bytes = crypto.getRandomValues(new Uint8Array(ID_LENGTH));
  let id = '';
  for (let i = 0; i < ID_LENGTH; i++) {
    id += ALPHABET[bytes[i] % ALPHABET.length];
  }
  return id;
}
