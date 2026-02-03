import { fetchBranches } from "./api.js";

const STORAGE_KEY = "admin_selected_branch";
const listeners = new Set();
let state = {
  branches: [],
  selected: localStorage.getItem(STORAGE_KEY) || "all",
};
let switcher = null;
let allowAllSelection = false;

function notify() {
  listeners.forEach((fn) => fn(state.selected));
  refreshSwitcher();
}

function refreshSwitcher() {
  if (!switcher) return;
  const options = [];
  if (allowAllSelection) {
    options.push({ value: "all", label: "All branches" });
  }
  state.branches.forEach((branch) => {
    options.push({ value: branch.id, label: branch.name });
  });
  switcher.innerHTML = options
    .map((option) => `<option value="${option.value}">${option.label}</option>`)
    .join("");
  if (!state.selected || (!allowAllSelection && optionMissing(state.selected))) {
    state.selected = state.branches[0]?.id || "all";
    localStorage.setItem(STORAGE_KEY, state.selected);
  }
  switcher.value = state.selected;
}

function optionMissing(value) {
  if (value === "all") return !allowAllSelection;
  return !state.branches.some((branch) => branch.id === value);
}

export async function initBranchState({ role, profileBranchId }) {
  const { data } = await fetchBranches();
  state.branches = data || [];
  if (role === "super_admin") {
    if (!state.selected || optionMissing(state.selected)) {
      state.selected = state.branches.length === 1 ? state.branches[0].id : "all";
    }
  } else {
    // For multi-branch users (granted via RLS + staff_branch_access), respect their last selection.
    // Otherwise default to their profile branch.
    const stored = state.selected;
    const hasMultipleBranches = state.branches.length > 1;
    const storedIsValid =
      (stored === "all" && hasMultipleBranches) || state.branches.some((branch) => branch.id === stored);
    state.selected = storedIsValid ? stored : profileBranchId || state.branches[0]?.id || "all";
  }
  localStorage.setItem(STORAGE_KEY, state.selected);
  notify();
  return state.branches;
}

export function getSelectedBranchId() {
  return state.selected;
}

export function getBranches() {
  return state.branches;
}

export function getBranchLabel(branchId) {
  if (!branchId || branchId === "all") return "All branches";
  const branch = state.branches.find((b) => b.id === branchId);
  return branch ? branch.name : "Unknown Branch";
}

export function onBranchChange(fn) {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

export function setSelectedBranch(branchId) {
  if (branchId === state.selected) return;
  state.selected = branchId;
  localStorage.setItem(STORAGE_KEY, branchId);
  notify();
}

export function registerBranchSwitcher(selectElement, { allowAll = false } = {}) {
  if (!selectElement) return;
  switcher = selectElement;
  // Auto-enable "All branches" when the user has access to multiple branches.
  // Super admins can always use "All branches".
  allowAllSelection = allowAll || state.branches.length > 1;
  switcher.addEventListener("change", () => {
    setSelectedBranch(switcher.value);
  });
  refreshSwitcher();
}
