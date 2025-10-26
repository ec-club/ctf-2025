"use client";
import Link from "next/link";
import { toast } from "sonner";
import { useRouter } from "next/navigation";
import { useId, useState } from "react";

import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";

import { RegisterUserWidget } from "@/widgets/user/Register";

export default function RegisterPage() {
  const router = useRouter();
  const formId = useId();
  const [isLoading, setIsLoading] = useState(false);
  return (
    <main className="mx-auto mt-8 container text-white">
      <header className="flex flex-col gap-2 justify-center items-center">
        <h2 className="text-xl">Sign up</h2>
        <p>
          Already have an account?{" "}
          <Link href="/login" className="text-blue-500">
            Log in
          </Link>
        </p>
      </header>
      <RegisterUserWidget
        formId={formId}
        onStartLoading={setIsLoading.bind(null, true)}
        onStopLoading={setIsLoading.bind(null, false)}
        onSuccess={() => {
          toast.success("Signed up successfully.");
          router.replace("/login");
        }}
      />
      <Button className="mt-4" type="submit" form={formId} disabled={isLoading}>
        {isLoading && <Spinner />}
        Register
      </Button>
    </main>
  );
}
