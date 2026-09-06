import app from "../src/index.js";

async function runAuthTests() {
  const PORT = 5056;
  const server = app.listen(PORT, async () => {
    try {
      const baseUrl = `http://localhost:${PORT}`;

      // Test 1: Register new user
      const registerRes = await fetch(`${baseUrl}/api/auth/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: "student@example.com",
          password: "password123",
          fullName: "Sagar Learner",
        }),
      });
      const registerData = await registerRes.json();
      if (!registerData.success || !registerData.data.token) {
        throw new Error("Registration test failed");
      }
      const authToken = registerData.data.token;

      // Test 2: Reject duplicate email
      const dupRes = await fetch(`${baseUrl}/api/auth/register`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: "student@example.com",
          password: "password123",
          fullName: "Another Person",
        }),
      });
      const dupData = await dupRes.json();
      if (dupRes.status !== 400 || dupData.success !== false) {
        throw new Error("Duplicate email rejection failed");
      }

      // Test 3: Login with correct credentials
      const loginRes = await fetch(`${baseUrl}/api/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: "student@example.com",
          password: "password123",
        }),
      });
      const loginData = await loginRes.json();
      if (!loginData.success || !loginData.data.token) {
        throw new Error("Login test failed");
      }

      // Test 4: Reject login with wrong password
      const wrongPassRes = await fetch(`${baseUrl}/api/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          email: "student@example.com",
          password: "wrongPassword",
        }),
      });
      if (wrongPassRes.status !== 401) {
        throw new Error("Wrong password rejection failed");
      }

      // Test 5: Access protected /api/auth/me with valid token
      const meRes = await fetch(`${baseUrl}/api/auth/me`, {
        headers: { Authorization: `Bearer ${authToken}` },
      });
      const meData = await meRes.json();
      if (!meData.success || meData.data.email !== "student@example.com") {
        throw new Error("Protected /api/auth/me test failed");
      }

      // Test 6: Reject protected endpoint without token
      const noTokenRes = await fetch(`${baseUrl}/api/auth/me`);
      if (noTokenRes.status !== 401) {
        throw new Error("Unauthorized check failed");
      }

      // Test 7: Add user skill
      const addSkillRes = await fetch(`${baseUrl}/api/skills`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${authToken}`,
        },
        body: JSON.stringify({
          skillName: "PostgreSQL",
          proficiencyLevel: 4,
        }),
      });
      const addSkillData = await addSkillRes.json();
      if (!addSkillData.success || addSkillData.data.proficiency_level !== 4) {
        throw new Error("Add skill test failed");
      }

      // Test 8: Get user skills
      const getSkillsRes = await fetch(`${baseUrl}/api/skills`, {
        headers: { Authorization: `Bearer ${authToken}` },
      });
      const getSkillsData = await getSkillsRes.json();
      if (!getSkillsData.success || getSkillsData.data.length !== 1) {
        throw new Error("Get skills test failed");
      }

      console.log("All authentication and user skills tests passed successfully.");
      server.close();
      process.exit(0);
    } catch (err) {
      console.error("Auth test failed:", err.message);
      server.close();
      process.exit(1);
    }
  });
}

runAuthTests();

