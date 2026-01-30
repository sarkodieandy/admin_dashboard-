import {
  BarChart3,
  Bell,
  LayoutDashboard,
  MessageSquare,
  Package,
  Settings,
  ShoppingBag,
  SlidersHorizontal,
  Star,
  Users,
  UtensilsCrossed,
  Wallet,
} from "lucide-react";

import type { ComponentType } from "react";

export type NavItem = { href: string; label: string; icon: ComponentType<{ className?: string }> };

export const navItems: NavItem[] = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/orders", label: "Orders", icon: ShoppingBag },
  { href: "/chats", label: "Chats", icon: MessageSquare },
  { href: "/menu", label: "Menu", icon: UtensilsCrossed },
  { href: "/customers", label: "Customers", icon: Users },
  { href: "/riders", label: "Riders", icon: Package },
  { href: "/delivery-settings", label: "Delivery", icon: SlidersHorizontal },
  { href: "/promotions", label: "Promotions", icon: Wallet },
  { href: "/reviews", label: "Reviews & Support", icon: Star },
  { href: "/staff", label: "Staff & Roles", icon: Settings },
  { href: "/analytics", label: "Analytics", icon: BarChart3 },
  { href: "/notifications", label: "Notifications", icon: Bell },
];
