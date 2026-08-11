const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");

const TWO_FACTOR_API_KEY = defineSecret("TWO_FACTOR_API_KEY");
const OTP_TEMPLATE = "OTP1";

function normalizePhone(raw) {
  const digits = String(raw ?? "").replace(/\D/g, "");
  return digits.length > 10 ? digits.slice(-10) : digits;
}

/**
 * Sends an SMS OTP to the given 10-digit Indian phone number via 2Factor.in.
 * Returns the 2Factor session id — the API key itself never reaches the client.
 */
exports.sendCustomerOtp = onCall(
  { secrets: [TWO_FACTOR_API_KEY], region: "asia-south1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const phone = normalizePhone(request.data?.phone);
    if (phone.length !== 10) {
      throw new HttpsError("invalid-argument", "Enter a valid 10-digit phone number.");
    }

    const apiKey = TWO_FACTOR_API_KEY.value();
    const url = `https://2factor.in/API/V1/${apiKey}/SMS/${phone}/AUTOGEN/${OTP_TEMPLATE}`;

    const res = await fetch(url);
    const body = await res.json();

    if (body.Status !== "Success") {
      throw new HttpsError("internal", body.Details || "Could not send OTP.");
    }

    return { sessionId: body.Details };
  },
);

/**
 * Verifies the code the customer typed against the 2Factor session.
 */
exports.verifyCustomerOtp = onCall(
  { secrets: [TWO_FACTOR_API_KEY], region: "asia-south1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const sessionId = String(request.data?.sessionId ?? "").trim();
    const otp = String(request.data?.otp ?? "").trim();
    if (!sessionId || !otp) {
      throw new HttpsError("invalid-argument", "Missing session or OTP.");
    }

    const apiKey = TWO_FACTOR_API_KEY.value();
    const url = `https://2factor.in/API/V1/${apiKey}/SMS/VERIFY/${sessionId}/${otp}`;

    const res = await fetch(url);
    const body = await res.json();

    return { verified: body.Status === "Success" };
  },
);
