"use client";
import ms from "ms";
import { toast } from "sonner";
import { useState, useTransition } from "react";

import { Button } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";

import { revealSeed } from "@/core/fair-game/reveal-seed";

export function RevealSeedButton() {
  const [seed, setSeed] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();
  return seed ? (
    <code>{seed}</code>
  ) : (
    <Button
      onClick={() =>
        startTransition(async () => {
          const result = await revealSeed(Math.floor(Date.now() / ms("5m")));
          if (result.error) {
            toast.error(result.error);
            return;
          } else {
            setSeed(result.seed);
          }
        })
      }
      disabled={isPending}
    >
      {isPending && <Spinner />}
      Reveal seed
    </Button>
  );
}
