package lgo

import (
	"testing"
)

func BenchmarkInvokeEmptyFunc(b *testing.B) {
	lua := NewLua()
	lua.RegisterFunction("foo", func() {})
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		lua.RunString(`foo()`)
	}
}

func BenchmarkInvokeInt(b *testing.B) {
	lua := NewLua()
	lua.RegisterFunction("foo", func(i int) {})
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		lua.RunString(`foo(42)`)
	}
}

func BenchmarkInvokeInt2(b *testing.B) {
	lua := NewLua()
	lua.RegisterFunction("foo", func(i, j int) {})
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		lua.RunString(`foo(42, 93)`)
	}
}

func BenchmarkInvokeBool(b *testing.B) {
	lua := NewLua()
	lua.RegisterFunction("foo", func(arg bool) {})
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		lua.RunString(`foo(true)`)
	}
}

func BenchmarkInvokeInterface(b *testing.B) {
	lua := NewLua()
	lua.RegisterFunction("foo", func(arg interface{}) {})
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		lua.RunString(`foo(42)`)
	}
}

func BenchmarkInvokeString(b *testing.B) {
	lua := NewLua()
	lua.RegisterFunction("foo", func(arg string) {})
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		lua.RunString(`foo('foobar')`)
	}
}

func BenchmarkInvokeBytes(b *testing.B) {
	lua := NewLua()
	lua.RegisterFunction("foo", func(arg []byte) {})
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		lua.RunString(`foo('foobar')`)
	}
}

func BenchmarkInvokeSlice(b *testing.B) {
	lua := NewLua()
	lua.RegisterFunction("foo", func(arg []int) {})
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		lua.RunString(`foo{1}`)
	}
}

func BenchmarkInvokeSlice2(b *testing.B) {
	lua := NewLua()
	lua.RegisterFunction("foo", func(arg []int) {})
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		lua.RunString(`foo{1, 2}`)
	}
}

func BenchmarkInvokeMap(b *testing.B) {
	lua := NewLua()
	lua.RegisterFunction("foo", func(arg map[string]int) {})
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		lua.RunString(`foo{foo = 42}`)
	}
}

func BenchmarkInvokeMap2(b *testing.B) {
	lua := NewLua()
	lua.RegisterFunction("foo", func(arg map[string]int) {})
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		lua.RunString(`foo{foo = 42, bar = 92}`)
	}
}
