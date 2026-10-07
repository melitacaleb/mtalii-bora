export const SERVICES = [
  { key: 'safari', label: 'Wildlife safaris', icon: 'Binoculars', blurb: 'Game drives and Big Five tracking' },
  { key: 'culture', label: 'Cultural and heritage', icon: 'Landmark', blurb: 'Villages, museums and Swahili heritage' },
  { key: 'coast', label: 'Coast and beach', icon: 'Umbrella', blurb: 'Dhow trips, snorkelling and beaches' },
  { key: 'hiking', label: 'Mountain and hiking', icon: 'Mountain', blurb: "Mt Kenya, Hell's Gate and forest walks" },
  { key: 'transfer', label: 'Airport and transfers', icon: 'Plane', blurb: 'Pickups, road transfers and safari vehicles' },
  { key: 'birding', label: 'Birding and photography', icon: 'Camera', blurb: 'Lakes, hides and photo safaris' },
];
export const COMING_SOON = ['Accommodation', 'Park and event tickets', 'Car hire', 'Travel insurance'];
export const CATEGORY_TINT: Record<string, string> = { Safari: '#a8461f', Beach: '#0b4f6c', Mountain: '#1b3a4b', Lake: '#14506b', Culture: '#4a2511', City: '#243b53', Forest: '#17402b' };
export const landing = (role?: string | null) => (role === 'traveler' ? '/dashboard' : role === 'admin' ? '/admin' : '/provider');
export const safeNext = (n?: string | null) => (n && n.startsWith('/') && !n.startsWith('//') ? n : null);
