// Auth UI and session management

let currentUser = null;
let authResolve = null; // for awaiting sign-in from requireAuth

async function initAuth() {
  const { data: { session } } = await supabaseClient.auth.getSession();
  currentUser = session?.user || null;
  renderAuthUI();
  injectAuthModal();
  if (currentUser) checkUsernameRequired();

  supabaseClient.auth.onAuthStateChange((_event, session) => {
    currentUser = session?.user || null;
    renderAuthUI();
    if (currentUser) {
      checkUsernameRequired();
      if (authResolve) {
        authResolve(true);
        authResolve = null;
      }
    }
  });
}

function injectAuthModal() {
  const modal = document.createElement('div');
  modal.id = 'auth-modal';
  modal.innerHTML = `
    <div class="auth-backdrop" onclick="closeAuthModal()"></div>
    <div class="auth-panel">
      <h2 id="auth-modal-title">Sign in</h2>
      <p id="auth-modal-subtitle" class="auth-subtitle">Sign in or create an account</p>
      <form id="auth-form" onsubmit="handleAuthSubmit(event)">
        <input type="email" id="auth-email" placeholder="Email" required autocomplete="email">
        <input type="password" id="auth-password" placeholder="Password" required minlength="6" autocomplete="current-password">
        <div id="auth-error" class="auth-error"></div>
        <button type="submit" class="auth-submit" id="auth-submit-btn">Sign in</button>
      </form>
      <p class="auth-toggle">
        <span id="auth-toggle-text">Don't have an account?</span>
        <a href="#" id="auth-toggle-link" onclick="toggleAuthMode(event)">Sign up</a>
      </p>
      <button class="auth-close" onclick="closeAuthModal()">&times;</button>
    </div>
  `;

  // Username selection panel (shown after sign-in if no username set)
  const usernameModal = document.createElement('div');
  usernameModal.id = 'username-modal';
  usernameModal.innerHTML = `
    <div class="auth-backdrop"></div>
    <div class="auth-panel">
      <h2>Choose a username</h2>
      <p class="auth-subtitle">Pick a unique username for your profile</p>
      <form id="username-form" onsubmit="handleUsernameSubmit(event)">
        <input type="text" id="username-input" placeholder="Username" required minlength="3" maxlength="24" pattern="[a-zA-Z0-9_-]+" autocomplete="username">
        <p class="username-hint">Letters, numbers, hyphens, and underscores only</p>
        <div id="username-error" class="auth-error"></div>
        <button type="submit" class="auth-submit" id="username-submit-btn">Continue</button>
      </form>
    </div>
  `;
  document.body.appendChild(usernameModal);
  document.body.appendChild(modal);

  const style = document.createElement('style');
  style.textContent = `
    #auth-modal, #username-modal {
      display: none;
      position: fixed;
      inset: 0;
      z-index: 200;
      align-items: center;
      justify-content: center;
    }
    #auth-modal.active, #username-modal.active { display: flex; }
    .auth-backdrop {
      position: absolute;
      inset: 0;
      background: rgba(0,0,0,0.4);
      backdrop-filter: blur(2px);
    }
    .auth-panel {
      position: relative;
      background: #fff;
      border-radius: 16px;
      padding: 32px;
      width: 90%;
      max-width: 360px;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      box-shadow: 0 20px 60px rgba(0,0,0,0.15);
      animation: authSlideIn 0.25s cubic-bezier(0.34, 1.56, 0.64, 1);
    }
    @keyframes authSlideIn {
      from { transform: scale(0.95) translateY(10px); opacity: 0; }
      to { transform: scale(1) translateY(0); opacity: 1; }
    }
    .auth-panel h2 {
      font-family: Georgia, serif;
      font-size: 1.4rem;
      margin-bottom: 4px;
    }
    .auth-subtitle {
      color: #666;
      font-size: 0.85rem;
      margin-bottom: 20px;
    }
    #auth-form input, #username-form input {
      width: 100%;
      padding: 12px 14px;
      border: 1px solid #ddd;
      border-radius: 8px;
      font-size: 0.95rem;
      margin-bottom: 10px;
      transition: border-color 0.2s;
    }
    #auth-form input:focus, #username-form input:focus {
      outline: none;
      border-color: #000;
    }
    .auth-error {
      color: #d32f2f;
      font-size: 0.82rem;
      min-height: 20px;
      margin-bottom: 4px;
    }
    .auth-submit {
      width: 100%;
      padding: 12px;
      background: #000;
      color: #fff;
      border: none;
      border-radius: 24px;
      font-size: 0.95rem;
      font-weight: 600;
      cursor: pointer;
      transition: opacity 0.2s;
    }
    .auth-submit:hover { opacity: 0.85; }
    .auth-submit:disabled { opacity: 0.5; cursor: not-allowed; }
    .auth-toggle {
      text-align: center;
      margin-top: 16px;
      font-size: 0.85rem;
      color: #666;
    }
    .auth-toggle a {
      color: #000;
      font-weight: 600;
      text-decoration: none;
    }
    .auth-toggle a:hover { text-decoration: underline; }
    .auth-close {
      position: absolute;
      top: 12px;
      right: 16px;
      background: none;
      border: none;
      font-size: 1.5rem;
      cursor: pointer;
      color: #999;
      line-height: 1;
    }
    .auth-close:hover { color: #000; }
    .username-hint {
      font-size: 0.75rem;
      color: #999;
      margin: -4px 0 8px 2px;
    }
  `;
  document.head.appendChild(style);
}

let authMode = 'signin'; // 'signin' or 'signup'

function toggleAuthMode(e) {
  e.preventDefault();
  authMode = authMode === 'signin' ? 'signup' : 'signin';
  document.getElementById('auth-modal-title').textContent = authMode === 'signin' ? 'Sign in' : 'Create account';
  document.getElementById('auth-modal-subtitle').textContent = authMode === 'signin'
    ? 'Sign in or create an account'
    : 'Enter your email and choose a password';
  document.getElementById('auth-submit-btn').textContent = authMode === 'signin' ? 'Sign in' : 'Create account';
  document.getElementById('auth-toggle-text').textContent = authMode === 'signin'
    ? "Don't have an account?"
    : 'Already have an account?';
  document.getElementById('auth-toggle-link').textContent = authMode === 'signin' ? 'Sign up' : 'Sign in';
  document.getElementById('auth-error').textContent = '';
}

async function handleAuthSubmit(e) {
  e.preventDefault();
  const email = document.getElementById('auth-email').value.trim();
  const password = document.getElementById('auth-password').value;
  const errorEl = document.getElementById('auth-error');
  const btn = document.getElementById('auth-submit-btn');
  errorEl.textContent = '';
  btn.disabled = true;
  btn.textContent = 'Loading...';

  if (authMode === 'signin') {
    const { error } = await supabaseClient.auth.signInWithPassword({ email, password });
    if (error) {
      errorEl.textContent = error.message;
      btn.disabled = false;
      btn.textContent = 'Sign in';
    } else {
      closeAuthModal();
    }
  } else {
    const { error } = await supabaseClient.auth.signUp({ email, password });
    if (error) {
      errorEl.textContent = error.message;
      btn.disabled = false;
      btn.textContent = 'Create account';
    } else {
      closeAuthModal();
    }
  }
}

function signIn() {
  authMode = 'signin';
  document.getElementById('auth-modal-title').textContent = 'Sign in';
  document.getElementById('auth-modal-subtitle').textContent = 'Sign in or create an account';
  document.getElementById('auth-submit-btn').textContent = 'Sign in';
  document.getElementById('auth-toggle-text').textContent = "Don't have an account?";
  document.getElementById('auth-toggle-link').textContent = 'Sign up';
  document.getElementById('auth-error').textContent = '';
  document.getElementById('auth-email').value = '';
  document.getElementById('auth-password').value = '';
  document.getElementById('auth-modal').classList.add('active');
  document.getElementById('auth-email').focus();
}

function closeAuthModal() {
  document.getElementById('auth-modal').classList.remove('active');
  document.getElementById('auth-submit-btn').disabled = false;
  document.getElementById('auth-submit-btn').textContent = authMode === 'signin' ? 'Sign in' : 'Create account';
}

async function checkUsernameRequired() {
  if (!currentUser) return;
  const { data: profile } = await supabaseClient
    .from('profiles').select('username').eq('id', currentUser.id).single();
  if (!profile?.username) {
    document.getElementById('username-modal').classList.add('active');
    document.getElementById('username-input').focus();
  }
}

async function handleUsernameSubmit(e) {
  e.preventDefault();
  const input = document.getElementById('username-input');
  const errorEl = document.getElementById('username-error');
  const btn = document.getElementById('username-submit-btn');
  const username = input.value.trim().toLowerCase();
  errorEl.textContent = '';

  if (!/^[a-zA-Z0-9_-]{3,24}$/.test(username)) {
    errorEl.textContent = 'Username must be 3-24 characters (letters, numbers, hyphens, underscores)';
    return;
  }

  btn.disabled = true;
  btn.textContent = 'Saving...';

  const { error } = await supabaseClient.from('profiles').update({
    username: username
  }).eq('id', currentUser.id);

  if (error) {
    errorEl.textContent = error.message.includes('unique') ? 'Username already taken' : 'Error saving username';
    btn.disabled = false;
    btn.textContent = 'Continue';
  } else {
    document.getElementById('username-modal').classList.remove('active');
    // Refresh page if on profile
    if (typeof loadProfile === 'function') loadProfile();
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
    const name = currentUser.user_metadata?.full_name || currentUser.email?.split('@')[0] || 'User';
    const isProfilePage = window.location.pathname.endsWith('profile.html');
    container.innerHTML = `
      <div style="display:flex;align-items:center;gap:8px;">
        <a href="/profile.html" style="color:#000;text-decoration:none;font-weight:500;">${name}</a>
        ${isProfilePage ? '<button onclick="signOut()" style="background:none;border:1px solid #ddd;border-radius:16px;padding:4px 12px;cursor:pointer;font-size:0.8rem;">Sign out</button>' : ''}
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
  signIn();
  return false;
}
