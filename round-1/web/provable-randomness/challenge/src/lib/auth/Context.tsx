"use client";
import {
  createContext,
  Dispatch,
  ReactNode,
  SetStateAction,
  useContext,
  useState,
} from "react";

export type AuthState = {
  username: string;
  balance: number;
} | null;
export const AuthContext = createContext<{
  authState: AuthState;
  setAuthState: Dispatch<SetStateAction<AuthState>>;
}>({
  authState: null,
  setAuthState: () => {
    throw new Error(
      "setAuthState not provided. Did you forget to wrap your component in AuthProvider?"
    );
  },
});

export function useAuthContext() {
  const { authState, setAuthState } = useContext(AuthContext);
  return [authState, setAuthState] as const;
}

/**
 * @private Only used internally by AuthProvider
 */
export function AuthContextProvider({
  children,
  initialValue,
}: {
  children: ReactNode;
  initialValue: AuthState;
}) {
  const [authState, setAuthState] = useState<AuthState>(initialValue);
  return (
    <AuthContext value={{ authState, setAuthState }}>{children}</AuthContext>
  );
}
