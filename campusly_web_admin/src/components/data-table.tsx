import { useMemo, useState, type ReactNode } from "react";
import { ChevronLeft, ChevronRight, Inbox, Search, TriangleAlert } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Skeleton } from "@/components/ui/skeleton";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { cn } from "@/lib/utils";

export interface Column<T> {
  key: string;
  header: string;
  className?: string;
  cell: (row: T) => ReactNode;
}

interface DataTableProps<T> {
  data: T[] | undefined;
  columns: Column<T>[];
  rowKey: (row: T) => string;
  loading?: boolean;
  error?: unknown;
  searchPlaceholder?: string;
  searchValue?: (row: T) => string;
  filters?: ReactNode;
  emptyTitle?: string;
  emptyDescription?: string;
  emptyAction?: ReactNode;
  pageSize?: number;
  onRetry?: () => void;
}

export function DataTable<T>({
  data,
  columns,
  rowKey,
  loading,
  error,
  searchPlaceholder = "Search…",
  searchValue,
  filters,
  emptyTitle = "Nothing here yet",
  emptyDescription = "Records you add will appear in this table.",
  emptyAction,
  pageSize = 10,
  onRetry,
}: DataTableProps<T>) {
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);

  const filtered = useMemo(() => {
    if (!data) return [];
    if (!query.trim() || !searchValue) return data;
    const q = query.toLowerCase();
    return data.filter((row) => searchValue(row).toLowerCase().includes(q));
  }, [data, query, searchValue]);

  const pageCount = Math.max(1, Math.ceil(filtered.length / pageSize));
  const current = Math.min(page, pageCount);
  const rows = filtered.slice((current - 1) * pageSize, current * pageSize);

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
        {searchValue && (
          <div className="relative sm:max-w-xs sm:flex-1">
            <Search className="pointer-events-none absolute left-3 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              value={query}
              onChange={(e) => {
                setQuery(e.target.value);
                setPage(1);
              }}
              placeholder={searchPlaceholder}
              className="h-9 rounded-lg pl-9"
            />
          </div>
        )}
        {filters && <div className="flex flex-wrap items-center gap-2">{filters}</div>}
      </div>

      <div className="surface overflow-hidden">
        {error ? (
          <StateBlock
            icon={<TriangleAlert className="size-5 text-destructive" />}
            title="Couldn't load this data"
            description="Something went wrong while fetching records."
            action={
              onRetry && (
                <Button variant="outline" onClick={onRetry}>
                  Try again
                </Button>
              )
            }
          />
        ) : loading ? (
          <div className="space-y-3 p-5">
            {Array.from({ length: 6 }).map((_, i) => (
              <Skeleton key={i} className="h-10 w-full rounded-lg" />
            ))}
          </div>
        ) : rows.length === 0 ? (
          <StateBlock
            icon={<Inbox className="size-5 text-muted-foreground" />}
            title={query ? "No matches found" : emptyTitle}
            description={query ? `No records match "${query}".` : emptyDescription}
            action={!query ? emptyAction : undefined}
          />
        ) : (
          <Table>
            <TableHeader>
              <TableRow className="hover:bg-transparent">
                {columns.map((col) => (
                  <TableHead
                    key={col.key}
                    className={cn(
                      "h-11 text-xs font-medium uppercase tracking-wide text-muted-foreground",
                      col.className,
                    )}
                  >
                    {col.header}
                  </TableHead>
                ))}
              </TableRow>
            </TableHeader>
            <TableBody>
              {rows.map((row) => (
                <TableRow key={rowKey(row)} className="border-border/70">
                  {columns.map((col) => (
                    <TableCell key={col.key} className={cn("py-3", col.className)}>
                      {col.cell(row)}
                    </TableCell>
                  ))}
                </TableRow>
              ))}
            </TableBody>
          </Table>
        )}
      </div>

      {!loading && !error && filtered.length > 0 && (
        <div className="flex flex-col items-center justify-between gap-3 sm:flex-row">
          <p className="text-sm text-muted-foreground">
            Showing {(current - 1) * pageSize + 1}–{Math.min(current * pageSize, filtered.length)}{" "}
            of {filtered.length}
          </p>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              className="rounded-lg"
              disabled={current === 1}
              onClick={() => setPage(current - 1)}
            >
              <ChevronLeft className="size-4" /> Previous
            </Button>
            <span className="px-1 text-sm text-muted-foreground">
              Page {current} of {pageCount}
            </span>
            <Button
              variant="outline"
              size="sm"
              className="rounded-lg"
              disabled={current === pageCount}
              onClick={() => setPage(current + 1)}
            >
              Next <ChevronRight className="size-4" />
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}

function StateBlock({
  icon,
  title,
  description,
  action,
}: {
  icon: ReactNode;
  title: string;
  description: string;
  action?: ReactNode;
}) {
  return (
    <div className="flex flex-col items-center gap-3 px-6 py-16 text-center">
      <div className="flex size-11 items-center justify-center rounded-xl bg-muted">{icon}</div>
      <div className="space-y-1">
        <p className="font-medium">{title}</p>
        <p className="text-sm text-muted-foreground">{description}</p>
      </div>
      {action}
    </div>
  );
}
