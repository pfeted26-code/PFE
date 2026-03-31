import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Alert, AlertDescription } from "@/components/ui/alert";
import {
  Mail,
  AlertCircle,
  CheckCircle2,
  ArrowLeft,
  KeyRound,
  Lock,
  Sparkles,
} from "lucide-react";

const API_BASE_URL = "http://localhost:5000";
const API_URL = `${API_BASE_URL}/users`;

// Service functions
const forgotPasswordService = async (email) => {
  const response = await fetch(`${API_URL}/forgot-password`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email }),
  });

  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.message || "Failed to send reset code");
  }

  return response.json();
};

const resetPasswordService = async (email, code, newPassword) => {
  const response = await fetch(`${API_URL}/reset-password`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, code, newPassword }),
  });

  if (!response.ok) {
    const errorData = await response.json();
    throw new Error(errorData.message || "Failed to reset password");
  }

  return response.json();
};

export default function ForgotPasswordFlow() {
  const [step, setStep] = useState(1); // 1: email, 2: code, 3: new password
  const [email, setEmail] = useState("");
  const [code, setCode] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [loading, setLoading] = useState(false);
  const [emailError, setEmailError] = useState("");
  const [codeError, setCodeError] = useState("");
  const [passwordError, setPasswordError] = useState("");

  const validateEmail = () => {
    if (!email.trim()) {
      setEmailError("Email is required");
      return false;
    } else if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setEmailError("Invalid email address");
      return false;
    }
    setEmailError("");
    return true;
  };

  const validateCode = () => {
    if (!code.trim()) {
      setCodeError("Verification code is required");
      return false;
    } else if (code.length !== 8) {
      setCodeError("Code must be 8 characters");
      return false;
    }
    setCodeError("");
    return true;
  };

  const validatePassword = () => {
    const passwordRegex =
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;

    if (!newPassword) {
      setPasswordError("Password is required");
      return false;
    } else if (!passwordRegex.test(newPassword)) {
      setPasswordError(
        "Password must contain at least 8 characters, one uppercase, one lowercase, one number, and one special character"
      );
      return false;
    } else if (newPassword !== confirmPassword) {
      setPasswordError("Passwords do not match");
      return false;
    }
    setPasswordError("");
    return true;
  };

  const handleSendCode = async () => {
    setError("");
    setSuccess("");

    if (!validateEmail()) return;

    setLoading(true);
    try {
      const data = await forgotPasswordService(email.trim());
      setSuccess(data.message || "Verification code sent! Check your inbox.");
      setTimeout(() => {
        setStep(2);
        setSuccess("");
      }, 1500);
    } catch (err) {
      setError(err.message || "Something went wrong.");
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyCode = async () => {
  setError("");
  setSuccess("");

  if (!validateCode()) return;

  setLoading(true);

  try {
    const response = await fetch(`${API_URL}/verify-code`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: email.trim(),
        code: code.trim(),
      }),
    });

    const data = await response.json();

    if (!response.ok) {
      throw new Error(data.message);
    }

    setSuccess("Code verified successfully!");

    setTimeout(() => {
      setStep(3);
      setSuccess("");
    }, 1000);

  } catch (err) {
    setError(err.message);
  } finally {
    setLoading(false);
  }
};

  const handleResetPassword = async () => {
    setError("");
    setSuccess("");

    if (!validatePassword()) return;

    setLoading(true);
    try {
      const data = await resetPasswordService(
        email.trim(),
        code.trim(),
        newPassword
      );
      setSuccess(data.message || "Password reset successful!");
      setTimeout(() => {
        window.location.href = "/login";
      }, 2000);
    } catch (err) {
      setError(err.message || "Something went wrong.");
    } finally {
      setLoading(false);
    }
  };

  const handleBackToLogin = () => {
    window.location.href = "/login";
  };

  const handleBack = () => {
    setError("");
    setSuccess("");
    if (step === 2) {
      setStep(1);
      setCode("");
    } else if (step === 3) {
      setStep(2);
      setNewPassword("");
      setConfirmPassword("");
    }
  };

  const getIcon = () => {
    if (step === 1)
      return <Mail className="h-12 w-12 text-white drop-shadow-lg" />;
    if (step === 2)
      return <KeyRound className="h-12 w-12 text-white drop-shadow-lg" />;
    return <Lock className="h-12 w-12 text-white drop-shadow-lg" />;
  };

  const getTitle = () => {
    if (step === 1) return "Reset Password";
    if (step === 2) return "Verify Code";
    return "New Password";
  };

  const getDescription = () => {
    if (step === 1) return "Enter your email to receive a verification code";
    if (step === 2) return "Enter the 8-character code sent to your email";
    return "Create a strong new password";
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-slate-950 via-slate-900 to-slate-950 p-4 relative overflow-hidden">
      {/* Background animations */}
      <div className="absolute inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-96 h-96 bg-gradient-to-br from-purple-600/30 via-blue-600/30 to-cyan-600/30 rounded-full blur-3xl animate-pulse opacity-40"></div>
        <div className="absolute bottom-1/4 right-1/4 w-96 h-96 bg-gradient-to-tr from-pink-600/30 via-purple-600/30 to-blue-600/30 rounded-full blur-3xl animate-pulse opacity-40"></div>
        <div className="absolute top-1/2 left-1/2 w-[600px] h-[600px] bg-gradient-to-r from-cyan-600/20 to-blue-600/20 rounded-full blur-3xl animate-pulse opacity-30"></div>
        <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,.02)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,.02)_1px,transparent_1px)] bg-[size:100px_100px]"></div>
      </div>

      <Card className="w-full max-w-md border border-slate-800/50 backdrop-blur-xl bg-slate-900/60 shadow-2xl shadow-purple-900/20 relative z-10 overflow-hidden">
        <CardHeader className="space-y-4 text-center pb-8 relative">
          <div className="flex justify-center mb-2">
            <div className="relative group cursor-default">
              <div className="absolute inset-0 bg-gradient-to-br from-purple-500 via-blue-500 to-cyan-500 rounded-3xl blur-xl opacity-75 animate-pulse"></div>
              <div className="relative h-24 w-24 rounded-3xl bg-gradient-to-br from-purple-600 via-blue-600 to-cyan-600 flex items-center justify-center shadow-2xl border border-white/20">
                {getIcon()}
                <Sparkles className="absolute top-2 right-2 h-4 w-4 text-cyan-300 animate-pulse" />
              </div>
            </div>
          </div>

          <CardTitle className="text-4xl font-bold bg-gradient-to-r from-purple-400 via-blue-400 to-cyan-400 bg-clip-text text-transparent">
            {getTitle()}
          </CardTitle>
          <CardDescription className="text-slate-400">
            {getDescription()}
          </CardDescription>
        </CardHeader>

        <CardContent className="space-y-6 relative">
          {error && (
            <Alert className="bg-red-950/50 text-red-300 border-red-800/50">
              <AlertCircle className="h-4 w-4 text-red-400" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          {success && (
            <Alert className="bg-emerald-950/50 text-emerald-300 border-emerald-800/50">
              <CheckCircle2 className="h-4 w-4 text-emerald-400" />
              <AlertDescription>{success}</AlertDescription>
            </Alert>
          )}

          {/* Step 1: Email */}
          {step === 1 && (
            <>
              <div className="space-y-2">
                <Label htmlFor="email" className="text-slate-300">
                  Email Address
                </Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-3.5 h-5 w-5 text-slate-500" />
                  <Input
                    id="email"
                    type="email"
                    placeholder="you@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    onKeyDown={(e) => e.key === "Enter" && handleSendCode()}
                    className="pl-10 bg-slate-800/50 border-slate-700 text-slate-200 placeholder:text-slate-500"
                    disabled={loading}
                  />
                </div>
                {emailError && (
                  <p className="text-sm text-red-400 flex items-center gap-1">
                    <AlertCircle className="h-3 w-3" />
                    {emailError}
                  </p>
                )}
              </div>

              <Button
                onClick={handleSendCode}
                disabled={loading}
                className="w-full bg-gradient-to-r from-purple-600 via-blue-600 to-cyan-600 hover:from-purple-700 hover:via-blue-700 hover:to-cyan-700 text-white shadow-lg shadow-purple-900/50"
              >
                <Sparkles className="mr-2 h-5 w-5" />
                {loading ? "Sending..." : "Send Verification Code"}
              </Button>

              <Button
                onClick={handleBackToLogin}
                variant="outline"
                className="w-full border-slate-700 bg-slate-800/50 text-slate-300 hover:bg-slate-700/50 hover:text-slate-200"
                disabled={loading}
              >
                <ArrowLeft className="mr-2 h-5 w-5" />
                Back to Login
              </Button>
            </>
          )}

          {/* Step 2: Verification Code */}
          {step === 2 && (
            <>
              <div className="space-y-2">
                <Label htmlFor="code" className="text-slate-300">
                  Verification Code
                </Label>
                <div className="relative">
                  <KeyRound className="absolute left-3 top-3.5 h-5 w-5 text-slate-500" />
                  <Input
                    id="code"
                    type="text"
                    placeholder="Enter 8-character code"
                    value={code}
                    onChange={(e) => setCode(e.target.value)} 
                    onKeyDown={(e) => e.key === "Enter" && handleVerifyCode()}
                    className="pl-10 font-mono text-lg tracking-wider bg-slate-800/50 border-slate-700 text-slate-200 placeholder:text-slate-500"
                    maxLength={8}
                    disabled={loading}
                  />
                </div>
                {codeError && (
                  <p className="text-sm text-red-400 flex items-center gap-1">
                    <AlertCircle className="h-3 w-3" />
                    {codeError}
                  </p>
                )}
                <p className="text-xs text-slate-500">Code sent to: {email}</p>
              </div>

              <Button
                onClick={handleVerifyCode}
                disabled={loading}
                className="w-full bg-gradient-to-r from-purple-600 via-blue-600 to-cyan-600 hover:from-purple-700 hover:via-blue-700 hover:to-cyan-700 text-white shadow-lg shadow-purple-900/50"
              >
                <CheckCircle2 className="mr-2 h-5 w-5" />
                Verify Code
              </Button>

              <Button
                onClick={handleBack}
                variant="outline"
                className="w-full border-slate-700 bg-slate-800/50 text-slate-300 hover:bg-slate-700/50 hover:text-slate-200"
              >
                <ArrowLeft className="mr-2 h-5 w-5" />
                Back
              </Button>
            </>
          )}

          {/* Step 3: New Password */}
          {step === 3 && (
            <>
              <div className="space-y-2">
                <Label htmlFor="newPassword" className="text-slate-300">
                  New Password
                </Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-3.5 h-5 w-5 text-slate-500" />
                  <Input
                    id="newPassword"
                    type="password"
                    placeholder="Enter new password"
                    value={newPassword}
                    onChange={(e) => setNewPassword(e.target.value)}
                    className="pl-10 bg-slate-800/50 border-slate-700 text-slate-200 placeholder:text-slate-500"
                    disabled={loading}
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="confirmPassword" className="text-slate-300">
                  Confirm Password
                </Label>
                <div className="relative">
                  <Lock className="absolute left-3 top-3.5 h-5 w-5 text-slate-500" />
                  <Input
                    id="confirmPassword"
                    type="password"
                    placeholder="Confirm new password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    onKeyDown={(e) =>
                      e.key === "Enter" && handleResetPassword()
                    }
                    className="pl-10 bg-slate-800/50 border-slate-700 text-slate-200 placeholder:text-slate-500"
                    disabled={loading}
                  />
                </div>
                {passwordError && (
                  <p className="text-sm text-red-400 flex items-center gap-1">
                    <AlertCircle className="h-3 w-3" />
                    {passwordError}
                  </p>
                )}
                <p className="text-xs text-slate-500">
                  Must contain 8+ characters, uppercase, lowercase, number, and
                  special character
                </p>
              </div>

              <Button
                onClick={handleResetPassword}
                disabled={loading}
                className="w-full bg-gradient-to-r from-purple-600 via-blue-600 to-cyan-600 hover:from-purple-700 hover:via-blue-700 hover:to-cyan-700 text-white shadow-lg shadow-purple-900/50"
              >
                <Sparkles className="mr-2 h-5 w-5" />
                {loading ? "Resetting..." : "Reset Password"}
              </Button>

              <Button
                onClick={handleBack}
                variant="outline"
                className="w-full border-slate-700 bg-slate-800/50 text-slate-300 hover:bg-slate-700/50 hover:text-slate-200"
              >
                <ArrowLeft className="mr-2 h-5 w-5" />
                Back
              </Button>
            </>
          )}

          <p className="text-xs text-center text-slate-500 pt-4 border-t border-slate-800">
            {step === 1 && "You'll receive an email with verification code"}
            {step === 2 && "Code expires in 10 minutes"}
            {step === 3 && "Your password will be reset securely"}
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
