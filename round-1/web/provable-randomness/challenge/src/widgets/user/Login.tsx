"use client";
import z from "zod";
import { useForm } from "react-hook-form";
import { useState } from "react";
import { zodResolver } from "@hookform/resolvers/zod";
import { AlertCircleIcon } from "lucide-react";

import { cn } from "@/lib/utils";

import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";

import { loginUser } from "@/core/user/login";
import { loginSchema } from "@/core/user/login.schema";
import { useAuthContext } from "@/lib/auth/Context";

const formSchema = loginSchema;
export function LoginWidget({
  formId,
  className,
  onStartLoading,
  onStopLoading,
  onSuccess,
}: {
  formId?: string;
  className?: string;
  onStartLoading?: () => void;
  onStopLoading?: () => void;
  onSuccess?: () => void;
}) {
  const [_, setAuthState] = useAuthContext();

  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      username: "",
      password: "",
    },
  });
  const [error, setError] = useState<string | null>(null);
  async function onSubmit(data: z.infer<typeof formSchema>) {
    onStartLoading?.();
    setError(null);
    try {
      const result = await loginUser({
        username: data.username,
        password: data.password,
      });
      if (result.error) {
        return setError(result.error);
      }
      if (!result.user) {
        throw new Error("No user data returned");
      }
      setAuthState({
        username: result.user.username,
        balance: result.user.balance,
      });
      onSuccess?.();
    } catch {
      setError("Something went wrong. Please try again later.");
    } finally {
      onStopLoading?.();
    }
  }

  return (
    <Form {...form}>
      <form
        onSubmit={form.handleSubmit(onSubmit)}
        id={formId}
        className={cn("flex flex-col gap-4", className)}
      >
        <FormField
          control={form.control}
          name="username"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Username</FormLabel>
              <FormControl>
                <Input autoComplete="username" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <FormField
          control={form.control}
          name="password"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Password</FormLabel>
              <FormControl>
                <Input type="password" autoComplete="new-password" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        {error && (
          <Alert variant="destructive">
            <AlertCircleIcon />
            <AlertTitle>Error</AlertTitle>
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        )}
      </form>
    </Form>
  );
}
