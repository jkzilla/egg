import { Egg as EggIcon } from 'lucide-react'

export default function Header() {
  return (
    <header className="bg-white shadow-md">
      <div className="container mx-auto px-4 py-6">
        <div className="flex items-center gap-3">
          <EggIcon className="w-10 h-10 text-amber-600" />
          <div>
            <h1 className="text-3xl font-bold text-amber-900">Hailey's Garden</h1>
            <p className="text-amber-700">Fresh Farm Eggs</p>
          </div>
        </div>
      </div>
    </header>
  )
}
