from django.shortcuts import render, get_object_or_404
from .models import *
from .forms import *

def index(request):
    return render(request=request, template_name='library/index.html')

def book_catalog(request):
    context = {'all_books': book.objects.all()}
    return render(request=request, template_name='library/book/list.html', context=context)

def book_description(request, book_id):
    one_book = get_object_or_404(book, pk=book_id)
    return render(request=request, template_name='library/book/info.html', context={'one_book': one_book})

def add_book(request):
    if request.method=='POST':
        pass
    else:
        form = BookForm()
    return render(request, 'library/book/add_book.html', {'form':form})

def add_book(request):
    global form
    if request.method == 'POST':
        form = BookForm(request.POST)
        if form.is_valid():
            print(form.cleaned_data)
            book.objects.create(**form.cleaned_data)  # ** для распаковки словаря, чтобы не писать title=title
    else:
        form = BookForm()
    return render(request, 'library/book/add_book.html', {'form': form})

