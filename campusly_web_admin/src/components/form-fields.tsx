/* eslint-disable @typescript-eslint/no-explicit-any */
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from "@/components/ui/form";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

export { Form };

export function TextField({
  control,
  name,
  label,
  placeholder,
  textarea,
  type,
  autoFocus,
}: {
  control: any;
  name: any;
  label: string;
  placeholder?: string;
  textarea?: boolean;
  type?: string;
  autoFocus?: boolean;
}) {
  return (
    <FormField
      control={control}
      name={name}
      render={({ field }) => (
        <FormItem>
          <FormLabel>{label}</FormLabel>
          <FormControl>
            {textarea ? (
              <Textarea autoFocus={autoFocus} className="min-h-20 rounded-lg" placeholder={placeholder} {...field} />
            ) : (
              <Input autoFocus={autoFocus} type={type || "text"} className="h-10 rounded-lg" placeholder={placeholder} {...field} />
            )}
          </FormControl>
          <FormMessage />
        </FormItem>
      )}
    />
  );
}

export function SelectField({
  control,
  name,
  label,
  options,
  numeric,
}: {
  control: any;
  name: any;
  label: string;
  options: { value: string | number; label: string }[] | (string | number)[];
  numeric?: boolean;
}) {
  const normalized = options.map((o) =>
    typeof o === "object" ? o : { value: o, label: String(o) },
  );
  return (
    <FormField
      control={control}
      name={name}
      render={({ field }) => (
        <FormItem>
          <FormLabel>{label}</FormLabel>
          <Select
            value={String(field.value ?? "")}
            onValueChange={(v) => field.onChange(numeric ? Number(v) : v)}
          >
            <FormControl>
              <SelectTrigger className="h-10 w-full rounded-lg capitalize">
                <SelectValue placeholder="Select" />
              </SelectTrigger>
            </FormControl>
            <SelectContent>
              {normalized.map((o) => (
                <SelectItem key={String(o.value)} value={String(o.value)} className="capitalize">
                  {o.label}
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
          <FormMessage />
        </FormItem>
      )}
    />
  );
}
