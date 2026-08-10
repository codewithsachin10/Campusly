import type { LucideIcon } from "lucide-react";
import { motion } from "motion/react";
import { Skeleton } from "@/components/ui/skeleton";

interface StatCardProps {
  label: string;
  value?: number;
  icon: LucideIcon;
  hint?: string;
  loading?: boolean;
  index?: number;
}

export function StatCard({ label, value, icon: Icon, hint, loading, index = 0 }: StatCardProps) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.35, delay: index * 0.04, ease: [0.22, 1, 0.36, 1] }}
      className="surface p-5"
    >
      <div className="flex items-start justify-between gap-3">
        <p className="text-sm font-medium text-muted-foreground">{label}</p>
        <span className="flex size-9 items-center justify-center rounded-xl bg-primary/10 text-primary">
          <Icon className="size-[18px]" />
        </span>
      </div>
      {loading ? (
        <Skeleton className="mt-4 h-8 w-20 rounded-md" />
      ) : (
        <p className="mt-3 text-3xl font-semibold tracking-tight tabular-nums">
          {value?.toLocaleString() ?? "—"}
        </p>
      )}
      {hint && <p className="mt-1.5 text-xs text-muted-foreground">{hint}</p>}
    </motion.div>
  );
}
