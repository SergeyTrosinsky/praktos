from django.contrib import admin
from .models import book , Author

class bookAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'description', 'count_pages', 'price', 'cover_type', 'size', 'publication_date', 'author')
    list_display_links = ('id', 'title')
    search_fields = ('title',)
    list_editable =('price',)
    list_filter = ('author','cover_type','size')

class AuthorAdmin(admin.ModelAdmin):
    list_display = ('id', 'title')
    list_display_links = ('id', 'title')
    search_fields = ('title',)

admin.site.register(book, bookAdmin)
admin.site.register(Author, AuthorAdmin)