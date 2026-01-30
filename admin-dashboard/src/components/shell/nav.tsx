import type { ReactNode } from "react";

import { EmojiIcon } from "@/components/ui/emoji-icon";

export type NavItem = { href: string; label: string; icon: ReactNode };

function foodIcon(code: string, alt: string) {
  return <EmojiIcon code={code} alt={alt} className="h-4 w-4" />;
}

export const navItems: NavItem[] = [
  { href: "/dashboard", label: "Dashboard", icon: foodIcon("1f37d", "Dashboard") },
  { href: "/orders", label: "Orders", icon: foodIcon("1f35b", "Orders") },
  { href: "/chats", label: "Chats", icon: foodIcon("2615", "Chats") }, // coffee
  { href: "/menu", label: "Menu", icon: foodIcon("1f374", "Menu") },
  { href: "/customers", label: "Customers", icon: foodIcon("1f9c1", "Customers") }, // takeout box
  { href: "/riders", label: "Riders", icon: foodIcon("1f6f5", "Riders") }, // scooter
  { href: "/delivery-settings", label: "Delivery", icon: foodIcon("1f69a", "Delivery") }, // delivery truck
  { href: "/promotions", label: "Promotions", icon: foodIcon("1f381", "Promotions") }, // gift
  { href: "/reviews", label: "Reviews & Support", icon: foodIcon("2b50", "Reviews") }, // star
  { href: "/staff", label: "Staff & Roles", icon: foodIcon("1f468-200d-1f373", "Staff") }, // cook
  { href: "/analytics", label: "Analytics", icon: foodIcon("1f4c8", "Analytics") }, // chart
  { href: "/notifications", label: "Notifications", icon: foodIcon("1f514", "Notifications") },
];

