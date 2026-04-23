const fetch = require('node-fetch'); // Let's use native fetch if available, or just axios if node version is older. Actually Node 18+ has native fetch. Let's assume Node 18+.

async function testAll() {
  const baseUrl = 'http://localhost:3000/api/v1';
  console.log('Testing connection to MongoDB & Intelligence endpoints...');

  // 1. Register a test user
  const email = `test_intel_${Date.now()}@example.com`;
  const password = 'password123';
  
  console.log(`\n--- Registering User ${email} ---`);
  let res = await fetch(`${baseUrl}/auth/signup`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ name: 'Intel Tester', email, password })
  });
  let data = await res.json();
  if (!data.success) {
    console.error('Registration failed:', data);
    return;
  }
  
  const token = data.data.accessToken;
  console.log('User registered successfully. Token received.');

  // 2. Setup Profile with subjects so weak subject detection works
  console.log(`\n--- Setting up profile ---`);
  res = await fetch(`${baseUrl}/users/profile`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
    body: JSON.stringify({
      profile: { subjects: ['Math', 'Physics', 'History'] }
    })
  });
  data = await res.json();
  console.log('Profile setup success:', data.success);
  if (!data.success) console.log('Error:', JSON.stringify(data, null, 2));

  // 3. Create some study sessions
  console.log(`\n--- Creating Study Sessions ---`);
  const sessionIds = [];
  
  async function createAndEndSession(subject, duration) {
    console.log(`Creating session for ${subject}...`);
    const sRes = await fetch(`${baseUrl}/sessions`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ subject, plannedDurationMinutes: duration })
    });
    const sData = await sRes.json();
    if (!sData.success) {
      console.error(`Failed to create session for ${subject}:`, sData);
      return;
    }
    
    const sessionId = sData.data.id || sData.data._id;
    console.log(`Session created with ID: ${sessionId}. Ending it...`);
    
    const eRes = await fetch(`${baseUrl}/sessions/${sessionId}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
      body: JSON.stringify({ action: 'end', focusScore: 80 })
    });
    const eData = await eRes.json();
    if (!eData.success) console.error(`Failed to end session ${sessionId}:`, eData);
  }

  await createAndEndSession('Math', 120);
  await createAndEndSession('Physics', 60);
  
  console.log('Sessions processing completed.');

  // 4. Test Intelligence Endpoints
  console.log('\n--- Testing Intelligence Endpoints ---');
  const intelEndpoints = ['burnout', 'prediction', 'insights', 'performance'];
  for (const endpoint of intelEndpoints) {
    res = await fetch(`${baseUrl}/intelligence/${endpoint}`, {
      headers: { 'Authorization': `Bearer ${token}` }
    });
    data = await res.json();
    console.log(`[GET /intelligence/${endpoint}] success: ${data.success}`);
  }

  // 5. Test Analytics
  console.log(`\n--- Testing Analytics ---`);
  res = await fetch(`${baseUrl}/analytics/summary`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  data = await res.json();
  console.log('[GET /analytics/summary] success:', data.success);

  res = await fetch(`${baseUrl}/analytics/heatmap`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  data = await res.json();
  console.log('[GET /analytics/heatmap] success:', data.success);

  // 6. Test AI Chat
  console.log(`\n--- Testing AI Chat ---`);
  res = await fetch(`${baseUrl}/ai/chat`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` },
    body: JSON.stringify({ message: 'Hello AI Coach, can you help me study Math?' })
  });
  data = await res.json();
  console.log('[POST /ai/chat] success:', data.success);
  if (data.success) console.log('AI Reply:', data.data.reply);

  // 7. Test Streak
  console.log(`\n--- Testing Streak ---`);
  res = await fetch(`${baseUrl}/analytics/summary`, { // Streak info is inside summary
    headers: { 'Authorization': `Bearer ${token}` }
  });
  data = await res.json();
  if (data.success) console.log('Current Streak:', data.data.streak.current);

  console.log('\n--- All Features Test Completed ---');
}

testAll().catch(console.error);
