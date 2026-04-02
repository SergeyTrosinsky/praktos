from django import forms  
from .models import *    

class BookForm(forms.Form):
    title = forms.CharField(max_length=150, label='Название книги')
    description = forms.CharField(required=False, label='Описание')
    count_pages = forms.IntegerField(label='Количество страниц')
    price = forms.FloatField(label='Цена')
    cover_type = forms.CharField(label='Тип обложки')
    size = forms.CharField(label='Размер')
    author = forms.ModelChoiceField(queryset=Author.objects.all(), empty_label='Выбираем автора', label='Автор')