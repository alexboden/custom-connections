// Auth UI and session management

let currentUser = null;

async function initAuth() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  currentUser = session?.user || null;
  renderAuthUI();

  supabaseClient.auth.onAuthStateChange((_event, session) => {
    currentUser = session?.user || null;
    renderAuthUI();
  });
}

async function signIn() {
  const email = prompt('Enter your email:');
  if (!email) return;
  const password = prompt('Enter your password (min 6 chars):');
  if (!password) return;

  // Try sign in first
  const { error: signInError } = await supabaseClient.auth.signInWithPassword({ email, password });

  if (signInError) {
    // If invalid credentials, try signing up
    const { error: signUpError } = await supabaseClient.auth.signUp({ email, password });
    if (signUpError) {
      alert(signUpError.message);
    } else {
      alert('Account created! Check your email to confirm, then sign in again.');
    }
  }
}

async function signOut() {
  await supabaseClient.auth.signOut();
  currentUser = null;
  renderAuthUI();
}

function renderAuthUI() {
  let container = document.getElementById('auth-container');
  if (!container) {
    container = document.createElement('div');
    container.id = 'auth-container';
    container.style.cssText = 'position:fixed;top:16px;right:16px;z-index:50;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;font-size:0.85rem;';
    document.body.appendChild(container);
  }

  if (currentUser) {
    const name = currentUser.user_metadata?.full_name || currentUser.email || 'User';
    const avatar = currentUser.user_metadata?.avatar_url;
    container.innerHTML = `
      <div style="display:flex;align-items:center;gap:8px;">
        ${avatar ? `<img src="${avatar}" style="width:28px;height:28px;border-radius:50%;" alt="">` : ''}
        <a href="/profile.html" style="color:#000;text-decoration:none;font-weight:500;">${name}</a>
        <button onclick="signOut()" style="background:none;border:1px solid #ddd;border-radius:16px;padding:4px 12px;cursor:pointer;font-size:0.8rem;">Sign out</button>
      </div>
    `;
  } else {
    container.innerHTML = `
      <button onclick="signIn()" style="background:#000;color:#fff;border:none;border-radius:16px;padding:8px 16px;cursor:pointer;font-size:0.85rem;font-weight:500;">Sign in</button>
    `;
  }
}

function requireAuth(action) {
  if (currentUser) return true;
  if (confirm(`Sign in to ${action}?`)) {
    signIn();
  }
  return false;
}
