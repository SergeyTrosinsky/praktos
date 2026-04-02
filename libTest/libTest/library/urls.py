from django.urls import path
from library.views import *

urlpatterns = [
    path('', index, name='home_index'),                     
    path('list/', book_catalog, name='book_list'),          
    path('book/<int:book_id>', book_description, name='book_description'),  
    path('book/add-book/', add_book, name='add_book'),
]