"use client";
import RouletteSpinner from "roulette-spinner";
import { Ref, useImperativeHandle, useLayoutEffect, useRef } from "react";

import { rouletteSections } from "@/data/roulette";

export interface RouletteController {
  spinTo: (index: number) => Promise<void>;
}

export function Roulette({ ref }: { ref?: Ref<RouletteController> }) {
  const rouletteContainerRef = useRef<HTMLDivElement>(null);
  const rouletteRef = useRef<RouletteSpinner | null>(null);
  useImperativeHandle(ref, () => ({
    spinTo: async (index: number) => {
      if (!rouletteRef.current) {
        return;
      }
      return new Promise((resolve) => {
        if (!rouletteRef.current) {
          return resolve();
        }
        rouletteRef.current.onstop = resolve;
        rouletteRef.current?.rollByIndex(index);
      });
    },
  }));

  useLayoutEffect(() => {
    if (!rouletteContainerRef.current || rouletteRef.current) {
      return;
    }
    rouletteRef.current = new RouletteSpinner({
      container: rouletteContainerRef.current,
      sections: rouletteSections.map(({ value, color }) => ({
        value,
        background: { red: "#ff0000", green: "#00ff00", black: "#000000" }[
          color
        ],
        font_color: { red: "#ffffff", green: "#000000", black: "#ffffff" }[
          color
        ],
      })),
      board: { radius: 240 },
      settings: {
        border: {
          width: 1,
          color: "#888",
        },
      },
    });
  }, []);
  return <div ref={rouletteContainerRef} />;
}
